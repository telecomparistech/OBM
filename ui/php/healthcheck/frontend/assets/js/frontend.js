/******************************************************************************
 * Health Check Javascript
 *****************************************************************************/
function test(){
	alert("test");
}

$.obm = {};
$.obm.getModuleTemplate = function(callback) {
	$.ajax({
		url: "module.tpl",
		error: function(jqXhr) {
			var status = jqXhr.status;
			if ( status == 0 ) {
				status = 500;
			}
			callback(status);
		},
		success: function(code_html){
			callback(null,code_html);
		}
	});
};

$.obm.getCheckList = function(callback) {
	$.ajax({
		url: "/healthcheck/backend/HealthCheck.php/",
		error: function(jqXhr, errorType) {
			var status = jqXhr.status;
			if ( status == 0 || errorType) {
				status = 500;
			}
			callback(status);
		},
		success: function(checkList){
			if ($.isPlainObject(checkList)) {
				callback(null,checkList);
			} else {
				callback(500);
			}
		}
	});
};

$.obm.bootstrap = function(callback) {
	var actionDone=0, actionCount=2;
	var moduleTemplate = null;
	var checkList = null;

	var checkAllDone = function() {
		if ( actionCount == actionDone ) {
			callback(null, checkList, moduleTemplate);
		}
	};

	$.obm.getModuleTemplate(function(err,html) {
		if ( err ) {
			return callback("Fail to get the template");
		}
		moduleTemplate = html;
		actionDone++;
		checkAllDone();
	});
	$.obm.getCheckList(function(err,json) {
		if ( err ) {
			return callback("Fail to get the check list");
		}
		checkList = json;
		actionDone++;
		checkAllDone();
	});
}

$(document).ready( function(){
	$("#startCheckButton").click( function(){
		$.obm.hideStartButton(this);
		$("#introduction").addClass("visibility-hidden");
		$.obm.bootstrap(
			function(err, checkList, moduleTemplate) {
				if ( err ) {
					alert( "Error: "+err );
					return ;
				}
				$.obm.addModules(checkList, moduleTemplate);
				$.obm.runChecks(checkList);
			}
		);
	});
	$("#restartCheckButton").click(function() {
	  window.location.replace(window.location.pathname+"?autostart=true");
	});

	$("#pauseCheckButton").click(function() {
		$.obm.togglePauseButton(this);
	});
	$("#resumeCheckButton").click(function() {
		$.obm.togglePauseButton($("#pauseCheckButton"));
	});

	if ( $.getQuery().autostart == "true" ) {
	  $("#startCheckButton").click();
	}
});

$.obm.codeToStatus = {0: "success", 1: "warning", 2: "error"};

$.obm.runChecks = function(checkList) {
  require(["checkScheduler", "progressBar", "pubsub"], function(checkScheduler, progressBar, pubsub) {
    $.obm.realRunChecks(checkList, checkScheduler, progressBar, pubsub);
  });
};

$.obm.realRunChecks = function(checkList, checkScheduler, progressBar, pubsub) {
  var modulesStatus = {};
  checkList.modules.forEach(function(module) {
    modulesStatus[module.id] = {
      checksCount: module.checks.length,
      checksDone: 0,
      status: "success"
    };
  });
  var startTopic = pubsub.topic("checkScheduler:start");
  var endOfCheckTopic = pubsub.topic("checkScheduler:endOfCheck");
  var progressBarInstance = new progressBar();
  startTopic.subscribe(function(data) { progressBarInstance.setElementCount(data.checksCount); });
  endOfCheckTopic.subscribe(function(data) { progressBarInstance.increment(); });
  
  var endCallback = $.obm.callbacks.buildEndCallback();
  var checkStartCallback = $.obm.callbacks.buildCheckStartCallback();
  var checkCompleteCallback = $.obm.callbacks.buildCheckCompleteCallback(modulesStatus);
  var scheduler = new checkScheduler(checkList, $.obm.callbacks.buildUrlBuilder());
  scheduler.runChecks(checkStartCallback, checkCompleteCallback, endCallback);
};

$.obm.callbacks = {
  buildUrlBuilder: function() {
    return function(flatCheck) {
      return "/healthcheck/backend/HealthCheck.php/"+flatCheck.moduleId+"/" + flatCheck.checkId;
    };
  },
  buildCheckStartCallback: function() {
    return function(flatCheck) {
      $.obm.showModuleContainer(flatCheck.moduleId);
      $.obm.showCheckContainer(flatCheck.moduleId, flatCheck.checkId);
    };
  },
  buildCheckCompleteCallback: function(modulesStatus) {
    return function(flatCheck, checkResult) {
      var moduleStatus = modulesStatus[flatCheck.moduleId];
      moduleStatus.checksDone++;
      moduleStatus.status = $.obm.codeToStatus[checkResult.code];
      
      $.obm.setCheckStatus(flatCheck.moduleId, flatCheck.checkId, $.obm.codeToStatus[checkResult.code]);
      $.obm.displayCheckInfo(flatCheck.moduleId, flatCheck.checkId, checkResult.code, checkResult.messages);
      
      if ( moduleStatus.status == "error" || moduleStatus.checksCount == moduleStatus.checksDone ) {
	$.obm.setModuleStatus(flatCheck.moduleId, moduleStatus.status);
	if ( moduleStatus.status == "success" ) {
	  $.obm.closeModuleContainer(flatCheck.moduleId);
	} else {
	  $.obm.openCheckContainer(flatCheck.moduleId,flatCheck.checkId);
	}
      }
    };
  },
  buildEndCallback: function() {
    return function() {
      $("#restartCheckButton").removeClass("visibility-hidden");
    };
  }
};

$.obm.htmlId = function(moduleId, checkId) {
  return moduleId+"-"+checkId;
};

$.obm.addModules = function(checkList, moduleTemplate, testTemplate) {
    var counter = 0;
    checkList.modules.forEach(function(module) {
      module.checks.forEach(function(check) {
	check.htmlId = module.id+"-"+check.id;
      });
    });
    for( var index in checkList.modules){
      var output = Mustache.render(moduleTemplate, checkList.modules[index]);
      $("#modules-list").append(output);
    }
};

$.obm.displayCheckInfo = function(moduleId, checkId, code, messages) {
  var htmlId = $.obm.htmlId(moduleId, checkId);
  $("#"+htmlId+"-info").removeClass('visibility-hidden').addClass('visibility-visible text-' + $.obm.codeToStatus[code]);
  if (messages) {
  	$.obm.updateBadges(code);
	$("#"+htmlId+"-info").html("<strong>Messages:</strong><br/>" + messages.join("<br/>"));
  }
};

$.obm.updateBadges = function(code) {
	var badgeName = {"1" : "#badge-warnings", "2" : "#badge-errors" };
	if (code > 0){
		var value = $(badgeName[code]).text();
		value++;
		$(badgeName[code]).html(value);
	}
};

$.obm.showModuleContainer = function(id) {
	$("#"+id+"-header").removeClass('visibility-hidden').addClass('visibility-visible');
};

$.obm.showCheckContainer = function(moduleId, checkId) {
  var htmlId = $.obm.htmlId(moduleId, checkId);
  $("#"+htmlId+"-header").removeClass('visibility-hidden').addClass('visibility-visible');
};

$.obm.setModuleStatus = function(id, status) {
	$("#"+id).removeClass("test-info test-warning test-error test-success").addClass("test-"+status);
};

$.obm.setCheckStatus = function(moduleId, checkId, status) {
  var htmlId = $.obm.htmlId(moduleId, checkId);
  $("#"+htmlId).removeClass("test-info test-warning test-error test-success").addClass("test-"+status);
};

$.obm.closeModuleContainer = function(id) {
  $("#"+id+"-inner").removeClass("in");
}

$.obm.hideStartButton = function(startBtn) {
	if ( $(startBtn).css("display") != "none" ){
		$(startBtn).css("display","none");
		$("#restartWrapper").css("display","block");
	}
}
$.obm.togglePauseButton = function(pauseBtn) {
	if ( $(pauseBtn).css("display") != "none" ){
		$(pauseBtn).css("display","none");
		$("#resumeWrapper").css("display","block");
	} else {
		$(pauseBtn).css("display","block");
		$("#resumeWrapper").css("display","none");
	}
}

$.obm.openCheckContainer = function(moduleId, checkId) {
  var htmlId = $.obm.htmlId(moduleId, checkId);
  $("#"+htmlId+"-test").addClass("in");
}

$.obm.setAlert = function(status, message) {
	// To Do: Add Alert after progress bar, before #modules-list http://twitter.github.com/bootstrap/components.html#alerts
};