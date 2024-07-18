/*
 * Copyright (c) 2024, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * NOTE: this file is generated by generate_ann_mg.py
 *
 * Make changes there and run in this directory:
 *
 * > python generate_ann_mg.py
 *
 */

#include <cuvs/neighbors/ann_mg.hpp>

#include "ann_mg.cuh"

namespace cuvs::neighbors::mg {

#define CUVS_INST_ANN_MG_PQ(T, IdxT)                                                      \
  ann_mg_index<ivf_pq::index<IdxT>, T, IdxT> build(                                       \
    const raft::resources& handle,                                                        \
    const cuvs::neighbors::mg::nccl_clique& clique,                                       \
    const ivf_pq::mg_index_params& index_params,                                          \
    raft::host_matrix_view<const T, IdxT, row_major> index_dataset)                       \
  {                                                                                       \
    return std::move(                                                                     \
      cuvs::neighbors::mg::detail::build(handle, clique, index_params, index_dataset));   \
  }                                                                                       \
                                                                                          \
  void extend(const raft::resources& handle,                                              \
              const cuvs::neighbors::mg::nccl_clique& clique,                             \
              ann_mg_index<ivf_pq::index<IdxT>, T, IdxT>& index,                          \
              raft::host_matrix_view<const T, IdxT, row_major> new_vectors,               \
              std::optional<raft::host_vector_view<const IdxT, IdxT>> new_indices)        \
  {                                                                                       \
    cuvs::neighbors::mg::detail::extend(handle, clique, index, new_vectors, new_indices); \
  }                                                                                       \
                                                                                          \
  void search(const raft::resources& handle,                                              \
              const cuvs::neighbors::mg::nccl_clique& clique,                             \
              const ann_mg_index<ivf_pq::index<IdxT>, T, IdxT>& index,                    \
              const ivf_pq::search_params& search_params,                                 \
              raft::host_matrix_view<const T, IdxT, row_major> query_dataset,             \
              raft::host_matrix_view<IdxT, IdxT, row_major> neighbors,                    \
              raft::host_matrix_view<float, IdxT, row_major> distances,                   \
              uint64_t n_rows_per_batch)                                                  \
  {                                                                                       \
    cuvs::neighbors::mg::detail::search(handle,                                           \
                                        clique,                                           \
                                        index,                                            \
                                        search_params,                                    \
                                        query_dataset,                                    \
                                        neighbors,                                        \
                                        distances,                                        \
                                        n_rows_per_batch);                                \
  }                                                                                       \
                                                                                          \
  void serialize(const raft::resources& handle,                                           \
                 const cuvs::neighbors::mg::nccl_clique& clique,                          \
                 const ann_mg_index<ivf_pq::index<IdxT>, T, IdxT>& index,                 \
                 const std::string& filename)                                             \
  {                                                                                       \
    cuvs::neighbors::mg::detail::serialize(handle, clique, index, filename);              \
  }                                                                                       \
                                                                                          \
  template <>                                                                             \
  ann_mg_index<ivf_pq::index<IdxT>, T, IdxT> deserialize_pq<T, IdxT>(                     \
    const raft::resources& handle,                                                        \
    const cuvs::neighbors::mg::nccl_clique& clique,                                       \
    const std::string& filename)                                                          \
  {                                                                                       \
    return std::move(                                                                     \
      cuvs::neighbors::mg::detail::deserialize_pq<T, IdxT>(handle, clique, filename));    \
  }                                                                                       \
                                                                                          \
  template <>                                                                             \
  ann_mg_index<ivf_pq::index<IdxT>, T, IdxT> distribute_pq<T, IdxT>(                      \
    const raft::resources& handle,                                                        \
    const cuvs::neighbors::mg::nccl_clique& clique,                                       \
    const std::string& filename)                                                          \
  {                                                                                       \
    return std::move(                                                                     \
      cuvs::neighbors::mg::detail::distribute_pq<T, IdxT>(handle, clique, filename));     \
  }
CUVS_INST_ANN_MG_PQ(float, int64_t);

#undef CUVS_INST_ANN_MG_PQ

}  // namespace cuvs::neighbors::mg
