'use strict'

# Declare app level module which depends on filters, and services
App = angular.module('app', [
  'ui.router'

  'app.controllers'
  'app.directives'
  'app.services'
  'app.filters'
  'app.models'
])

App.config([
  '$locationProvider'
  '$stateProvider'
  '$urlRouterProvider'

($locationProvider, $stateProvider, $urlRouterProvider) ->
  $locationProvider.html5Mode(false).hashPrefix("!")

  $urlRouterProvider.otherwise '/'

  $stateProvider
    .state('home', {
      url: '/'
      templateUrl: 'partials/home.html'
    })
])

angular.element(document).ready ->
  angular.bootstrap(document, ['app'])

