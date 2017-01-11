require 'pry'

class Element
  include Comparable

  attr_accessor :name, :priority

  def initialize(name, priority)
    @name, @priority = name, priority
  end

  def <=>(other)
    @priority <=> other.priority
  end
end

class NaivePriorityQueue
  def initialize
    @elements = []
  end

  def <<(element)
    @elements << element
  end

  def pop
    last_element_index = @elements.size - 1
    @elements.sort!
    @elements.delete_at(last_element_index)
  end
end

# The problem with this is every time we pop we have to sort. This means it is computationally expensive. We add to the front, then we sort everytime we pop.

# One Solution: Binary Heap
# A binary heap is a complete binary tree. All nodes > children

class PriorityQueue
  def initialize
    @elements = [nil]
  end

  def <<(element)
    @elements << element
    bubble_up(@elements.size - 1)
  end

  def bubble_up(index)
    parent_index = (index/2)

    return if index <= 1

    return if @elements[parent_index] >= @elements[index]

    exchange(index, parent_index)

    bubble_up(parent_index)
  end

  def exchange(source, target)
    @elements[source], @elements[target] = @elements[target], @elements[source]
  end

  def pop
    exchange(1, @elements.size - 1)

    max = @elements.pop

    bubble_down(1)
    max
  end

  def bubble_down(index)
    child_index = (index * 2)

    return if child_index > @elements.size - 1

    not_the_last_element = child_index < @elements.size - 1
    left_element = @elements[child_index]
    right_element = @elements[child_index + 1]
    child_index += 1 if not_the_last_element && right_element > left_element

    return if @elements[index] >= @elements[child_index]

    exchange(index, child_index)

    bubble_down(child_index)
  end
end

# We need to put new nodes in the proper place in the tree, this is called heapify-up or bubble up.

################################################################################
##################### TIME DECAYED QUEUE #######################################
################################################################################
# We want to make sure that anything in the queue eventually has a way to make it out of the queue.
# But we also don't want to block.

# Scoring = commits_per_hour * hours_since_last_commit
# commits_per_hour ? last daily velocity : last daily velocity * A + average lifetime velocity * B : average lifetime velocity

# {
#   id:,
#   name:,
#   score:,
#   time_last_popped:,
#   value:,
# }

# In order to ensure that as time goes forward the values get larger on the queue
# we need to have small values be highest priority?

class TimeDecayPriorityQueue
  def initialize
    @elements = [nil]
  end

  def <<(element)
    element.recalculate_priority
    @elements << element
    bubble_up(@elements.size - 1)
  end

  def bubble_up(index)
    parent_index = (index/2)

    return if index <= 1

    return if @elements[parent_index] >= @elements[index]

    exchange(index, parent_index)

    bubble_up(parent_index)
  end

  def exchange(source, target)
    @elements[source], @elements[target] = @elements[target], @elements[source]
  end

  def pop
    exchange(1, @elements.size - 1)

    max = @elements.pop

    bubble_down(1)
    max
  end

  def bubble_down(index)
    child_index = (index * 2)

    return if child_index > @elements.size - 1

    not_the_last_element = child_index < @elements.size - 1
    left_element = @elements[child_index]
    right_element = @elements[child_index + 1]
    child_index += 1 if not_the_last_element && right_element > left_element

    return if @elements[index] >= @elements[child_index]

    exchange(index, child_index)

    bubble_down(child_index)
  end
end

REFERENCE_TIME = Time.new(2017, 1, 1, 0, 0, 0) # begining of the year

class TimeDecayElement
  include Comparable

  attr_accessor :priority_score, :name

  def initialize(id, name, value)
    @id, @name, @value = id, name, value

    recalculate_priority
  end

  def recalculate_priority
    @priority_score = @value / (Time.now - REFERENCE_TIME)
  end

  def <=>(other)
    @priority_score <=> other.priority_score
  end

end

# 1 * 100
#
# 2 * 100
#
# 3 * 100
#
# 4 * 100
#
# 100 / 4 = 25
# 200 / 4 = 50
# 200 / 5 = 40
# 200 / 6 = 34
# 200 / 7 = 30

# We also need to check when thing are added to the queue.

# Assume A, B, C

# A has 1 commit per hour
# B has .5 and C has .2
# They are all initially divided by the same time and so end up in order of
# commit velocity
# [A, B, C]
# When A is popped however, time has increased, it's score is smaller.
# [B, A, C]
# When B is popped it is smaller than A but not C
# [A, B, C]
# C will maintain its position until time becomes large enough that it drives
# A behind C
# [B, C, A]
# [C, A, B]

q = TimeDecayPriorityQueue.new
q << TimeDecayElement.new(0, "A", 100)
q << TimeDecayElement.new(1, "B", 100)
q << TimeDecayElement.new(2, "C", 10)
q << TimeDecayElement.new(3, "D", 1)

# PROBLEM: Every factor of 10 in value means time must grow by 10 before the
# smallest value is brought to the front. Ex. let's say T0 is 1000, the score of
# A = 0.1, the score of D = 0.001. In order for D to surpass A T0 must be
# 100 / x  <= 0.001 or 100000. This will take far too long.

################################################################################
###################### RELATIVE DECAY ##########################################
################################################################################

class RelativePriorityQueue
  def initialize
    @elements = [nil]
  end

  def <<(element)
    element.recalculate_priority
    @elements << element
    bubble_up(@elements.size - 1)
  end

  def bubble_up(index)
    parent_index = (index/2)

    return if index <= 1

    return if @elements[parent_index] >= @elements[index]

    exchange(index, parent_index)

    bubble_up(parent_index)
  end

  def exchange(source, target)
    @elements[source], @elements[target] = @elements[target], @elements[source]
  end

  def pop
    exchange(1, @elements.size - 1)

    max = @elements.pop
    max.increment # recalls how many times it was popped, decreases its priority

    bubble_down(1)
    max
  end

  def pop_and_push
    ele = pop
    self.<<(ele)
  end

  def bubble_down(index)
    child_index = (index * 2)

    return if child_index > @elements.size - 1

    not_the_last_element = child_index < @elements.size - 1
    left_element = @elements[child_index]
    right_element = @elements[child_index + 1]
    child_index += 1 if not_the_last_element && right_element > left_element

    return if @elements[index] >= @elements[child_index]

    exchange(index, child_index)

    bubble_down(child_index)
  end
end

class RelativeDecayElement
  include Comparable

  attr_accessor :priority_score, :name

  def initialize(id, name, value)
    @id, @name, @value = id, name, value

    @times_popped = 0

    recalculate_priority
  end

  def increment
    @times_popped += 1
  end

  def recalculate_priority
    @priority_score = @value / (@times_popped + 1)
  end

  def <=>(other)
    @priority_score <=> other.priority_score
  end
end

q = RelativePriorityQueue.new
q << RelativeDecayElement.new(0, "A", 100.0)
q << RelativeDecayElement.new(1, "B", 100.0)
q << RelativeDecayElement.new(2, "C", 10.0)
q << RelativeDecayElement.new(3, "D", 1.0)

binding.pry
