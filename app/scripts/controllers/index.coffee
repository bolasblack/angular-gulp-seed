'use strict'

url = require 'url'

### Controllers ###

angular.module('app.controllers', [
  'ngCookies'

  'ui.bootstrap'
])

.controller('HomeController', [
  '$scope'
  ($scope) ->
    $scope.query = url.parse(location.href, true).query
])
