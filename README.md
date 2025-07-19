# Bitz

A pure Ruby dynamic bitset implementation

## Features

- **Dynamic resizing**: Automatically grows buffer as needed when setting bits
- **Memory efficient**: Uses packed byte arrays for optimal memory usage
- **Ruby-idiomatic**: Standard operators (`&`, `|`, `!`) and method chaining support
- **0-indexed**: Bit positions start from 0, following standard conventions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bitz'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bitz

## Usage

### Basic Operations

```ruby
require 'bitz'

# Create a new bitset with default capacity (64 bits)
bitset = Bitz::Set.new

# Set individual bits
bitset.set(5)
bitset.set(10)
bitset.set(15)

# Check if bits are set
bitset.set?(5)   # => true
bitset.set?(3)   # => false
bitset.set?(100) # => nil (position doesn't exist yet)

# Unset bits
bitset.unset(10)
bitset.set?(10)  # => false

# Count set bits
bitset.count     # => 2 (bits 5 and 15 are set)

# Get total capacity
bitset.capacity  # => 64
```

### Bulk Operations

```ruby
# Set all bits to 1
bitset.set_all
bitset.count     # => 64

# Set all bits to 0
bitset.unset_all
bitset.count     # => 0
```

### Custom Initialization

```ruby
# Create bitset with specific capacity
large_bitset = Bitz::Set.new(256)

# Create bitset with all bits initially set
filled_bitset = Bitz::Set.new(64, fill: true)
filled_bitset.count  # => 64
```

### Set Operations

#### Mutating Operations

```ruby
set1 = Bitz::Set.new
set1.set(1)
set1.set(2)

set2 = Bitz::Set.new
set2.set(2)
set2.set(3)

# Union (modifies set1)
set1.set_union(set2)
# set1 now contains bits 1, 2, 3

set1 = Bitz::Set.new
set1.set(1)
set1.set(2)

# Intersection (modifies set1)
set1.set_intersection(set2)
# set1 now contains only bit 2
```

#### Non-mutating Operations

```ruby
set1 = Bitz::Set.new
set1.set(1)
set1.set(2)

set2 = Bitz::Set.new  
set2.set(2)
set2.set(3)

# Union (creates new bitset)
union_result = set1 | set2
# union_result contains bits 1, 2, 3
# set1 and set2 are unchanged

# Intersection (creates new bitset)
intersection_result = set1 & set2
# intersection_result contains only bit 2
# set1 and set2 are unchanged

# Complement/NOT (creates new bitset with all bits flipped)
complement_result = !set1
# complement_result has all bits flipped - bits 0, 3, 4, 5, ..., 63 are set
# set1 is unchanged
```

### Copying

```ruby
original = Bitz::Set.new
original.set(5)

# Create independent copy
copy = original.dup
copy.set(10)

original.set?(10)  # => false (original unchanged)
copy.set?(5)       # => true (copy has original's bits)
```

## API Reference

### Constructor

- `Bitz::Set.new(bits = 64, fill: false)` - Create bitset with initial capacity

### Bit Manipulation

- `set(bit)` - Set bit at position to 1
- `unset(bit)` - Set bit at position to 0  
- `set?(bit)` - Check if bit is set (returns true/false/nil)

### Bulk Operations

- `set_all` - Set all bits to 1
- `unset_all` - Set all bits to 0
- `count` - Count number of set bits
- `capacity` - Get total bit capacity

### Set Operations (Mutating)

- `set_union(other)` - Union with another bitset (modifies self)
- `set_intersection(other)` - Intersection with another bitset (modifies self)

### Set Operations (Non-mutating)

- `|(other)` - Union operator (returns new bitset)
- `&(other)` - Intersection operator (returns new bitset)
- `!` - Complement/NOT operator (returns new bitset with all bits flipped)

### Copying

- `dup` - Create independent copy of bitset

## Error Handling

Operations between bitsets with different capacities will raise `ArgumentError`:

```ruby
set1 = Bitz::Set.new(64)
set2 = Bitz::Set.new(128)

set1 | set2  # => ArgumentError: Cannot union bitsets with different capacities: 64 != 128
```

## Development

After checking out the repo, run tests with:

```bash
rake test
```

This will run the full test suite including:
- Basic bit manipulation tests
- Set operation tests  
- Error condition tests
- Performance validation tests

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [Apache 2.0](https://opensource.org/licenses/MIT).
