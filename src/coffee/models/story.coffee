class JiraStoryTime.Models.Story extends JiraStoryTime.Utils.Observer
  @_fieldIds =
    id: "id"
    key: "issuekey"
    description: "description"
    summary: "summary"
    business: "customfield_10003"
    points: "customfield_10002"
    epic: "customfield_10007"
    version: "fixVersions"

  isCurrent: false
  isOpen: false
  visible_default: true

  constructor: (@basicData, @rapidView, @applicationState) ->
    super()
    @id = @basicData.id
    @observe(@applicationState)
    @getFullStory()
    @updateState()

  onObservedChange: (change) =>
    if change.object is @applicationState
      @updateState()

  updateIsCurrent: (currentIssues) =>
    @isCurrent = currentIssues.indexOf(@id) > -1

  toggelOpen: =>
    @isOpen = not @isOpen

  updateState: =>
    if @applicationState.autoUpdate is true
      unless @autoUpdateInterval?
        @autoUpdateInterval = setInterval(@getFullStory, 10000 + Math.random() * 5000)
    else
      if @autoUpdateInterval?
        clearInterval @autoUpdateInterval
        delete @autoUpdateInterval

    @serverSync = @applicationState.serverSync

  getFullStory: =>
    $.ajax(
      url: "/rest/greenhopper/1.0/xboard/issue/details.json?" +
        "issueIdOrKey=#{@id}&loadSubtasks=true&rapidViewId=#{@rapidView}"
      context: this
    ).done @setMoreData

  setMoreData: (data) =>
    @moreData = data
    data.fields.forEach (f) =>
      switch f.id
        when @constructor._fieldIds.key
          @key = f.text
        when @constructor._fieldIds.summary
          @summary = f.text
        when @constructor._fieldIds.points
          @points = @_parsePoints f[f.renderer]
        when @constructor._fieldIds.business
          @business = @_parsePoints f[f.renderer]
        when @constructor._fieldIds.description
          @description = f.html
        when @constructor._fieldIds.epic
          @epic = f.text
        when @constructor._fieldIds.version
          @version = f.text

  setProperty: (prop, points) =>
    @[prop] = points
    if @serverSync
      data =
        fieldId: @constructor._fieldIds[prop]
        issueIdOrKey: @id
        newValue: points
      $.ajax(
        url: "/rest/greenhopper/1.0/xboard/issue/update-field.json"
        context: document.body
        type: "PUT"
        headers:
          "Content-Type": "application/json"
        data: JSON.stringify data
      ).done (response) ->
        console.log response
    else
      console.log("#{@key}: #{prop} would have been updated to #{points}")

  isVisible: () =>
    vis = true
    Object.keys(@).forEach (k) =>
      if /^visible/.test(k)
        vis = vis && @[k]
      true
    vis

  _parsePoints: (text) ->
    ret = parseInt text
    if ret then ret else undefined

  deconstruct: =>
    clearInterval @autoUpdateInterval
    delete @autoUpdateInterval
    @unobserveAll()
