class JiraStoryTime.Views.Subset extends JiraStoryTime.Utils.Observer
  constructor: (@subset) ->
    super()
    @observe @subset
    @el = $(JiraStoryTime.Utils.Templates.get('subset.html'))
    @el.addClass("epic-color-#{@subset.color}")
    @el.find('input[type=checkbox]').attr('id', "epic-#{@subset.subsetVar}-#{@subset.color}")
    @el.find('label').attr('for', "epic-#{@subset.subsetVar}-#{@subset.color}")
    @el.find('.epic-name').html(@subset.name)
    @el.find('input[type=checkbox]').on 'change', @subset.toggleVisibility
    @updatePoints()

  onObservedChange: (change) =>
    @updatePoints()

  updatePoints: () =>
    @el.find('.story-points').html("#{@subset.points} / #{@subset.business}")

  deconstruct: () =>
    @unobserveAll()
    @el.find('checkbox').off()
    @el.remove()
