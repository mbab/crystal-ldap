require "../request"

class LDAP::Request::Filter
  enum Type
    NotEqual
    Equal
    GreaterThanOrEqual
    LessThanOrEqual
    And
    Or
    Not

    # TODO:: Implement this
    Extensible
  end

  def initialize(@operation : Type, @filter : BER)
  end

  getter operation : Type

  def to_ber
    @filter
  end

  def self.equal(object : String, value)
    value = value.to_s
    if value == "*"
      self.new(Type::Equal, BER.new.set_string(object, 7, TagClass::ContextSpecific))
    elsif value =~ /[*]/
      # TODO
      raise "not implemented"
    else
      left = BER.new.set_string(object, UniversalTags::OctetString)
      right = BER.new.set_string(value, UniversalTags::OctetString)
      self.new(Type::Equal, LDAP.context_sequence({left, right}, 3))
    end
  end

  def self.greater_than(object : String, value)
    left = BER.new.set_string(object, UniversalTags::OctetString)
    right = BER.new.set_string(value.to_s, UniversalTags::OctetString)
    self.new(Type::GreaterThanOrEqual, LDAP.context_sequence({left, right}, 5))
  end

  def self.less_than(object : String, value)
    left = BER.new.set_string(object, UniversalTags::OctetString)
    right = BER.new.set_string(value.to_s, UniversalTags::OctetString)
    self.new(Type::LessThanOrEqual, LDAP.context_sequence({left, right}, 6))
  end

  def self.not_equal(object : String, value)
    self.new(
      Type::NotEqual,
      LDAP.context_sequence({self.class.equal(object, value).to_ber}, 2)
    )
  end

  def self.negate(filter : Filter)
    self.new(Type::Not, LDAP.context_sequence({filter.to_ber}, 2))
  end

  def self.negate(filter : BER)
    self.new(Type::Not, LDAP.context_sequence({filter}, 2))
  end

  def self.join(left : BER, right : BER)
    self.new(Type::And, LDAP.context_sequence({left, right}, 0))
  end

  def self.join(left : Filter, right : Filter)
    self.new(Type::And, LDAP.context_sequence({left.to_ber, right.to_ber}, 0))
  end

  def intersect(left : BER, right : BER)
    self.new(Type::Or, LDAP.context_sequence({left, right}, 1))
  end

  def intersect(left : Filter, right : Filter)
    self.new(Type::Or, LDAP.context_sequence({left.to_ber, right.to_ber}, 1))
  end

  # Joins two or more filters so that all conditions must be true.
  def &(filter)
    self.class.join(self, filter)
  end

  # Selects entries where either the left or right side are true.
  def |(filter)
    self.class.intersect(self, filter)
  end

  # Negates a filter.
  def ~
    self.class.negate(self)
  end
end
