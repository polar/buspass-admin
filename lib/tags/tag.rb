class Tag
  def setup
    @master ||= page.master!
    @municipality ||= page.municipality!
    @network ||= page.network!
    @route ||= page.route!
    @service ||= page.service!
    @vehicle_journey ||= page.vehicle_journey!
  end

  def content
    setup
    ""
  end
end