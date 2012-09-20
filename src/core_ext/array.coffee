
Object.defineProperties Array::,
  first:  get: (-> @[0]), set: (v) -> @[0] = v
  second: get: (-> @[1]), set: (v) -> @[1] = v
  last:
    get:     -> @[@length - 1] if @length > 0
    set: (v) -> @[@length - 1] = v if @length > 0

Array::toSentence = (wordsConnector = 'and') ->
  @join(', ').replace /,\s([^,]+)$/, " #{wordsConnector} $1"

