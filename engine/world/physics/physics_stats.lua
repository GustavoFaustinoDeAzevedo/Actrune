local PhysicsStats = {}
PhysicsStats.__index = PhysicsStats

-- Creates an initially empty set of statistics for one physics step.
function PhysicsStats.new()
  local self = setmetatable({}, PhysicsStats)
  self:reset()
  return self
end

-- Clears all statistics collected during the previous physics step.
function PhysicsStats:reset()
  self.collision_iterations = 0
  self.broadphase_pairs = 0
  self.narrowphase_tests = 0
  self.cached_contacts = 0
end

-- Records one collision-search iteration.
function PhysicsStats:record_collision_iteration()
  self.collision_iterations = self.collision_iterations + 1
end

-- Records the work performed by one broad- and narrow-phase search.
function PhysicsStats:record_collision_search(broadphase_pairs, narrowphase_tests)
  self.broadphase_pairs = self.broadphase_pairs + broadphase_pairs
  self.narrowphase_tests = self.narrowphase_tests + narrowphase_tests
end

-- Records the number of persistent contacts after the physics step.
function PhysicsStats:set_cached_contacts(count)
  self.cached_contacts = count
end

return PhysicsStats
