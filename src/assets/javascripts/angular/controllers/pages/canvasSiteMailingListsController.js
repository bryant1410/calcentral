'use strict';

var angular = require('angular');

/**
 * Canvas Site Mailing Lists app controller; for the admin-level tool allowing administration of all bCourses mailing lists.
 */
angular.module('calcentral.controllers').controller('CanvasSiteMailingListsController', function(apiService, canvasSiteMailingListsFactory, dateFilter, $scope) {
  apiService.util.setTitle('Manage Site Mailing List');

  var errorCallback = function() {
    $scope.displayError = 'failure';
  };

  /*
   * Initializes application upon loading.
   */
  var initState = function() {
    $scope.canvasSite = {};
    $scope.mailingList = {};
    setStateFromData({});
  };

  var setStateFromData = function(data) {
    $scope.isProcessing = false;
    $scope.alerts = {
      error: (data.errorMessages || []),
      success: []
    };
    angular.extend($scope, data);
    $scope.siteSelected = (data.canvasSite && !!data.canvasSite.canvasCourseId);
    $scope.listRegistered = (data.mailingList && data.mailingList.state !== 'unregistered');
    $scope.listCreated = (data.mailingList && data.mailingList.state === 'created');
    $scope.listPending = $scope.listRegistered && !$scope.listCreated;

    if ($scope.siteSelected) {
      setCodeAndTerm($scope.canvasSite);
    }

    if (!$scope.listRegistered) {
      // For Fall 2016, the list admin tool should continue to default to CalMail.
      $scope.mailingList.listType = 'CalmailList';
    }

    if ($scope.listCreated) {
      setListLastPopulated(data.mailingList);
    }

    if (data.populationResults) {
      showPopulationResults(data.populationResults);
    }
  };

  var setCodeAndTerm = function(canvasSite) {
    var codeAndTermArray = [];
    if (canvasSite.courseCode !== canvasSite.name) {
      codeAndTermArray.push(canvasSite.courseCode);
    }
    if (canvasSite.term && canvasSite.term.name) {
      codeAndTermArray.push(canvasSite.term.name);
    }
    canvasSite.codeAndTerm = codeAndTermArray.join(', ');
  };

  var setListLastPopulated = function(list) {
    if (list.timeLastPopulated) {
      $scope.listLastPopulated = dateFilter((list.timeLastPopulated.epoch * 1000), 'short');
    } else {
      $scope.listLastPopulated = 'never';
    }
  };

  var showPopulationResults = function(results) {
    if (results.success) {
      $scope.alerts.success.push('Memberships were successfully updated.');
      if (results.messages.length) {
        $scope.alerts.success = $scope.alerts.success.concat(results.messages);
      } else {
        $scope.alerts.success.push('No changes in membership were found.');
      }
    } else {
      $scope.alerts.error.push('There were errors during the last membership update.');
      $scope.alerts.error = $scope.alerts.error.concat(results.messages);
      $scope.alerts.error.push('You can attempt to correct the errors by running the update again.');
    }
  };

  $scope.confirmCreation = function() {
    $scope.isConfirmingCreation = true;
    return canvasSiteMailingListsFactory.getSiteMailingList($scope.canvasSite.canvasCourseId).then(
      function successCallback(response) {
        $scope.isConfirmingCreation = false;
        setStateFromData(response.data);
        if (!$scope.listCreated && !$scope.alerts.error.count) {
          $scope.alerts.error.push('You cannot update memberships before the list is created in CalMail.');
        }
      },
      errorCallback
    );
  };

  $scope.findSiteMailingList = function() {
    $scope.isProcessing = true;
    return canvasSiteMailingListsFactory.getSiteMailingList($scope.canvasSite.canvasCourseId).then(
      function successCallback(response) {
        setStateFromData(response.data);
      },
      errorCallback
    );
  };

  $scope.populateMailingList = function() {
    $scope.isProcessing = true;
    return canvasSiteMailingListsFactory.populateSiteMailingList($scope.canvasSite.canvasCourseId).then(
      function successCallback(response) {
        setStateFromData(response.data);
        if (!response.data || !response.data.populationResults) {
          $scope.alerts.error.push('The mailing list could not be populated.');
        }
      },
      errorCallback
    );
  };

  $scope.registerMailingList = function() {
    $scope.isProcessing = true;
    return canvasSiteMailingListsFactory.registerSiteMailingList($scope.canvasSite.canvasCourseId, $scope.mailingList).then(
      function successCallback(response) {
        setStateFromData(response.data);
      },
      errorCallback
    );
  };

  $scope.resetForm = function() {
    initState();
  };

  $scope.unregisterMailingList = function() {
    $scope.isProcessing = true;
    return canvasSiteMailingListsFactory.deleteSiteMailingList($scope.canvasSite.canvasCourseId).then(
      function successCallback() {
        initState();
      },
      errorCallback
    );
  };

  // Wait until user profile is fully loaded before starting.
  $scope.$on('calcentral.api.user.isAuthenticated', function(event, isAuthenticated) {
    if (isAuthenticated) {
      initState();
    }
  });
});
