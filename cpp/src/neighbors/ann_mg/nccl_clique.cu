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

#include <cuvs/neighbors/ann_mg.hpp>
#include <raft/comms/std_comms.hpp>

namespace cuvs::neighbors::mg {

nccl_clique::nccl_clique(const std::vector<int>& device_ids)
  : root_rank_(0),
    num_ranks_(device_ids.size()),
    device_ids_(device_ids),
    nccl_comms_(device_ids.size()),
    per_device_pools_(0),
    device_resources_(0)
{
  RAFT_NCCL_TRY(ncclCommInitAll(nccl_comms_.data(), num_ranks_, device_ids_.data()));

  for (int rank = 0; rank < num_ranks_; rank++) {
    RAFT_CUDA_TRY(cudaSetDevice(device_ids[rank]));

    // create a pool memory resource for each device
    auto old_mr = rmm::mr::get_current_device_resource();
    per_device_pools_.push_back(
      std::make_unique<pool_mr>(old_mr, rmm::percent_of_free_device_memory(80)));
    rmm::cuda_device_id id(device_ids[rank]);
    rmm::mr::set_per_device_resource(id, per_device_pools_.back().get());

    // create a device resource handle for each device
    device_resources_.emplace_back();

    // add NCCL communications to the device resource handle
    raft::comms::build_comms_nccl_only(
      &device_resources_[rank], nccl_comms_[rank], num_ranks_, rank);
  }

  for (int rank = 0; rank < num_ranks_; rank++) {
    RAFT_CUDA_TRY(cudaSetDevice(device_ids[rank]));
    raft::resource::sync_stream(device_resources_[rank]);
  }
}

const raft::device_resources& nccl_clique::set_current_device_to_root_rank() const
{
  int root_device_id = device_ids_[root_rank_];
  RAFT_CUDA_TRY(cudaSetDevice(root_device_id));
  return device_resources_[root_rank_];
}

nccl_clique::~nccl_clique()
{
  for (int rank = 0; rank < num_ranks_; rank++) {
    cudaSetDevice(device_ids_[rank]);
    ncclCommDestroy(nccl_comms_[rank]);
    rmm::cuda_device_id id(device_ids_[rank]);
    rmm::mr::set_per_device_resource(id, nullptr);
  }
}

}  // namespace cuvs::neighbors::mg