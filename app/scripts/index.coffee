'use strict'

angular.module('app', [
  'ui.router'
  'ngAria'

  'app.controllers'
  'app.directives'
  'app.services'
  'app.filters'
  'app.models'
])

.config([
  '$locationProvider', '$stateProvider', '$urlRouterProvider'
  ($locationProvider ,  $stateProvider ,  $urlRouterProvider) ->
    $locationProvider.html5Mode(false).hashPrefix("!")

    $urlRouterProvider.otherwise '/'

    $stateProvider
      .state('home', {
        url: '/'
        templateUrl: 'partials/home.html'
        controller: 'HomeController'
      })
])

# Add state class to html element, example:
#   state: user           ->  page-user
#   state: user.settings  ->  page-user-settings
.run([
  '$rootScope', '$state'
  ($rootScope ,  $state) ->
    $rootScope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
      $htmlElem = angular.element 'html'
      isClassnameCreatedBySelf = (classname) -> /^page-/.test classname
      oldClassnames = ($htmlElem.attr('class') ? '').split(' ').filter(isClassnameCreatedBySelf).join ' '
      $htmlElem.removeClass(oldClassnames)

      nestedStates = toState.name.split('.')
      _.range(nestedStates.length).forEach (index) ->
        (states = nestedStates.slice 0, index + 1).unshift 'page'
        $htmlElem.addClass states.join '-'
])

angular.element(document).ready ->
  angular.bootstrap(document, ['app'])
