class Persona
  attr_reader :name, :description, :relationship_to_other, :ghost_threshold

  def initialize(name:, description:, relationship_to_other:, ghost_threshold: 0.5)
    @name = name
    @description = description
    @relationship_to_other = relationship_to_other
    @ghost_threshold = ghost_threshold
  end

  def to_h
    {
      name: @name,
      description: @description,
      relationship_to_other: @relationship_to_other,
      ghost_threshold: @ghost_threshold
    }
  end
end