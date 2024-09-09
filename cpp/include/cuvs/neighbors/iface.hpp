#include <cuvs/neighbors/cagra.hpp>
#include <cuvs/neighbors/common.hpp>
#include <cuvs/neighbors/ivf_flat.hpp>
#include <cuvs/neighbors/ivf_pq.hpp>

namespace cuvs::neighbors {

using namespace raft;

template <typename AnnIndexType, typename T, typename IdxT>
class iface {
 public:
  template <typename Accessor>
  void build(raft::resources const& handle,
             const cuvs::neighbors::index_params* index_params,
             raft::mdspan<const T, matrix_extent<int64_t>, row_major, Accessor> index_dataset);

  template <typename Accessor1, typename Accessor2>
  void extend(
    raft::resources const& handle,
    raft::mdspan<const T, matrix_extent<int64_t>, row_major, Accessor1> new_vectors,
    std::optional<raft::mdspan<const IdxT, vector_extent<int64_t>, layout_c_contiguous, Accessor2>>
      new_indices);

  void search(raft::resources const& handle,
              const cuvs::neighbors::search_params* search_params,
              raft::host_matrix_view<const T, int64_t, row_major> h_queries,
              raft::device_matrix_view<IdxT, int64_t, row_major> d_neighbors,
              raft::device_matrix_view<float, int64_t, row_major> d_distances) const;

  void serialize(raft::resources const& handle, std::ostream& os) const;
  void deserialize(raft::resources const& handle, std::istream& is);
  void deserialize(raft::resources const& handle, const std::string& filename);
  const IdxT size() const;

 private:
  std::optional<AnnIndexType> index_;
};

template <typename AnnIndexType, typename T, typename IdxT>
template <typename Accessor>
void iface<AnnIndexType, T, IdxT>::build(
  raft::resources const& handle,
  const cuvs::neighbors::index_params* index_params,
  raft::mdspan<const T, matrix_extent<int64_t>, row_major, Accessor> index_dataset)
{
  if constexpr (std::is_same<AnnIndexType, ivf_flat::index<T, IdxT>>::value) {
    auto idx = cuvs::neighbors::ivf_flat::build(
      handle, *static_cast<const ivf_flat::index_params*>(index_params), index_dataset);
    index_.emplace(std::move(idx));
  } else if constexpr (std::is_same<AnnIndexType, ivf_pq::index<IdxT>>::value) {
    auto idx = cuvs::neighbors::ivf_pq::build(
      handle, *static_cast<const ivf_pq::index_params*>(index_params), index_dataset);
    index_.emplace(std::move(idx));
  } else if constexpr (std::is_same<AnnIndexType, cagra::index<T, IdxT>>::value) {
    cagra::index<T, IdxT> idx(handle);
    idx = cuvs::neighbors::cagra::build(
      handle, *static_cast<const cagra::index_params*>(index_params), index_dataset);
    index_.emplace(std::move(idx));
  }
  resource::sync_stream(handle);
}

template <typename AnnIndexType, typename T, typename IdxT>
template <typename Accessor1, typename Accessor2>
void iface<AnnIndexType, T, IdxT>::extend(
  raft::resources const& handle,
  raft::mdspan<const T, matrix_extent<int64_t>, row_major, Accessor1> new_vectors,
  std::optional<raft::mdspan<const IdxT, vector_extent<int64_t>, layout_c_contiguous, Accessor2>>
    new_indices)
{
  if constexpr (std::is_same<AnnIndexType, ivf_flat::index<T, IdxT>>::value) {
    auto idx = cuvs::neighbors::ivf_flat::extend(handle, new_vectors, new_indices, index_.value());
    index_.emplace(std::move(idx));
  } else if constexpr (std::is_same<AnnIndexType, ivf_pq::index<IdxT>>::value) {
    auto idx = cuvs::neighbors::ivf_pq::extend(handle, new_vectors, new_indices, index_.value());
    index_.emplace(std::move(idx));
  } else if constexpr (std::is_same<AnnIndexType, cagra::index<T, IdxT>>::value) {
    RAFT_FAIL("CAGRA does not implement the extend method");
  }
  resource::sync_stream(handle);
}

template <typename AnnIndexType, typename T, typename IdxT>
void iface<AnnIndexType, T, IdxT>::search(
  raft::resources const& handle,
  const cuvs::neighbors::search_params* search_params,
  raft::host_matrix_view<const T, int64_t, row_major> h_queries,
  raft::device_matrix_view<IdxT, int64_t, row_major> d_neighbors,
  raft::device_matrix_view<float, int64_t, row_major> d_distances) const
{
  int64_t n_rows = h_queries.extent(0);
  int64_t n_dims = h_queries.extent(1);
  auto d_queries = raft::make_device_matrix<T, int64_t, row_major>(handle, n_rows, n_dims);
  raft::copy(d_queries.data_handle(),
             h_queries.data_handle(),
             n_rows * n_dims,
             resource::get_cuda_stream(handle));
  auto d_query_view = raft::make_const_mdspan(d_queries.view());

  if constexpr (std::is_same<AnnIndexType, ivf_flat::index<T, int64_t>>::value) {
    cuvs::neighbors::ivf_flat::search(
      handle,
      *reinterpret_cast<const ivf_flat::search_params*>(search_params),
      index_.value(),
      d_query_view,
      d_neighbors,
      d_distances);
  } else if constexpr (std::is_same<AnnIndexType, ivf_pq::index<int64_t>>::value) {
    cuvs::neighbors::ivf_pq::search(handle,
                                    *reinterpret_cast<const ivf_pq::search_params*>(search_params),
                                    index_.value(),
                                    d_query_view,
                                    d_neighbors,
                                    d_distances);
  } else if constexpr (std::is_same<AnnIndexType, cagra::index<T, uint32_t>>::value) {
    cuvs::neighbors::cagra::search(handle,
                                   *reinterpret_cast<const cagra::search_params*>(search_params),
                                   index_.value(),
                                   d_query_view,
                                   d_neighbors,
                                   d_distances);
  }
  resource::sync_stream(handle);
}

template <typename AnnIndexType, typename T, typename IdxT>
void iface<AnnIndexType, T, IdxT>::serialize(raft::resources const& handle, std::ostream& os) const
{
  if constexpr (std::is_same<AnnIndexType, ivf_flat::index<T, IdxT>>::value) {
    ivf_flat::serialize(handle, os, index_.value());
  } else if constexpr (std::is_same<AnnIndexType, ivf_pq::index<IdxT>>::value) {
    ivf_pq::serialize(handle, os, index_.value());
  } else if constexpr (std::is_same<AnnIndexType, cagra::index<T, IdxT>>::value) {
    cagra::serialize(handle, os, index_.value(), true);
  }
}

template <typename AnnIndexType, typename T, typename IdxT>
void iface<AnnIndexType, T, IdxT>::deserialize(raft::resources const& handle, std::istream& is)
{
  if constexpr (std::is_same<AnnIndexType, ivf_flat::index<T, IdxT>>::value) {
    ivf_flat::index<T, IdxT> idx(handle);
    ivf_flat::deserialize(handle, is, &idx);
    index_.emplace(std::move(idx));
  } else if constexpr (std::is_same<AnnIndexType, ivf_pq::index<IdxT>>::value) {
    ivf_pq::index<IdxT> idx(handle);
    ivf_pq::deserialize(handle, is, &idx);
    index_.emplace(std::move(idx));
  } else if constexpr (std::is_same<AnnIndexType, cagra::index<T, IdxT>>::value) {
    cagra::index<T, IdxT> idx(handle);
    cagra::deserialize(handle, is, &idx);
    index_.emplace(std::move(idx));
  }
}

template <typename AnnIndexType, typename T, typename IdxT>
void iface<AnnIndexType, T, IdxT>::deserialize(raft::resources const& handle,
                                               const std::string& filename)
{
  std::ifstream is(filename, std::ios::in | std::ios::binary);
  if (!is) { RAFT_FAIL("Cannot open file %s", filename.c_str()); }

  if constexpr (std::is_same<AnnIndexType, ivf_flat::index<T, IdxT>>::value) {
    ivf_flat::index<T, IdxT> idx(handle);
    ivf_flat::deserialize(handle, is, &idx);
    index_.emplace(std::move(idx));
  } else if constexpr (std::is_same<AnnIndexType, ivf_pq::index<IdxT>>::value) {
    ivf_pq::index<IdxT> idx(handle);
    ivf_pq::deserialize(handle, is, &idx);
    index_.emplace(std::move(idx));
  } else if constexpr (std::is_same<AnnIndexType, cagra::index<T, IdxT>>::value) {
    cagra::index<T, IdxT> idx(handle);
    cagra::deserialize(handle, is, &idx);
    index_.emplace(std::move(idx));
  }

  is.close();
}

template <typename AnnIndexType, typename T, typename IdxT>
const IdxT iface<AnnIndexType, T, IdxT>::size() const
{
  if constexpr (std::is_same<AnnIndexType, ivf_flat::index<T, IdxT>>::value) {
    return index_.value().size();
  } else if constexpr (std::is_same<AnnIndexType, ivf_pq::index<IdxT>>::value) {
    return index_.value().size();
  } else if constexpr (std::is_same<AnnIndexType, cagra::index<T, IdxT>>::value) {
    return index_.value().size();
  }
}

};  // namespace cuvs::neighbors