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

#include "ann_mg.cuh"

namespace cuvs::neighbors::mg {

#define CUVS_INST_ANN_MG_FLAT(T, IdxT)                                                           \
  ann_mg_index<ivf_flat::index<T, IdxT>, T, IdxT> build(                                         \
    const raft::resources& handle,                                                               \
    const cuvs::neighbors::mg::nccl_clique& clique,                                              \
    const ivf_flat::mg_index_params& index_params,                                               \
    raft::host_matrix_view<const T, int64_t, row_major> index_dataset)                           \
  {                                                                                              \
    return std::move(                                                                            \
      cuvs::neighbors::mg::detail::build<T, IdxT>(handle, clique, index_params, index_dataset)); \
  }                                                                                              \
                                                                                                 \
  void extend(const raft::resources& handle,                                                     \
              const cuvs::neighbors::mg::nccl_clique& clique,                                    \
              ann_mg_index<ivf_flat::index<T, IdxT>, T, IdxT>& index,                            \
              raft::host_matrix_view<const T, int64_t, row_major> new_vectors,                   \
              std::optional<raft::host_vector_view<const IdxT, int64_t>> new_indices)            \
  {                                                                                              \
    cuvs::neighbors::mg::detail::extend(handle, clique, index, new_vectors, new_indices);        \
  }                                                                                              \
                                                                                                 \
  void search(const raft::resources& handle,                                                     \
              const cuvs::neighbors::mg::nccl_clique& clique,                                    \
              const ann_mg_index<ivf_flat::index<T, IdxT>, T, IdxT>& index,                      \
              const ivf_flat::search_params& search_params,                                      \
              raft::host_matrix_view<const T, int64_t, row_major> queries,                       \
              raft::host_matrix_view<IdxT, int64_t, row_major> neighbors,                        \
              raft::host_matrix_view<float, int64_t, row_major> distances,                       \
              int64_t n_rows_per_batch)                                                          \
  {                                                                                              \
    cuvs::neighbors::mg::detail::search(                                                         \
      handle, clique, index, search_params, queries, neighbors, distances, n_rows_per_batch);    \
  }                                                                                              \
                                                                                                 \
  void serialize(const raft::resources& handle,                                                  \
                 const cuvs::neighbors::mg::nccl_clique& clique,                                 \
                 const ann_mg_index<ivf_flat::index<T, IdxT>, T, IdxT>& index,                   \
                 const std::string& filename)                                                    \
  {                                                                                              \
    cuvs::neighbors::mg::detail::serialize(handle, clique, index, filename);                     \
  }                                                                                              \
                                                                                                 \
  template <>                                                                                    \
  ann_mg_index<ivf_flat::index<T, IdxT>, T, IdxT> deserialize_flat<T, IdxT>(                     \
    const raft::resources& handle,                                                               \
    const cuvs::neighbors::mg::nccl_clique& clique,                                              \
    const std::string& filename)                                                                 \
  {                                                                                              \
    return std::move(                                                                            \
      cuvs::neighbors::mg::detail::deserialize_flat<T, IdxT>(handle, clique, filename));         \
  }                                                                                              \
                                                                                                 \
  template <>                                                                                    \
  ann_mg_index<ivf_flat::index<T, IdxT>, T, IdxT> distribute_flat<T, IdxT>(                      \
    const raft::resources& handle,                                                               \
    const cuvs::neighbors::mg::nccl_clique& clique,                                              \
    const std::string& filename)                                                                 \
  {                                                                                              \
    return std::move(                                                                            \
      cuvs::neighbors::mg::detail::distribute_flat<T, IdxT>(handle, clique, filename));          \
  }
CUVS_INST_ANN_MG_FLAT(int8_t, int64_t);

#undef CUVS_INST_ANN_MG_FLAT

}  // namespace cuvs::neighbors::mg
