<!DOCTYPE html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	
	<link href="./static/fenix-spaces/css/fullcalendar/fullcalendar.css" rel="stylesheet">
	<link href="./static/fenix-spaces/css/fullcalendar/fullcalendar.print.css" rel="stylesheet" media="print">
	<link rel="stylesheet" href="./static/fenix-spaces/css/datetimepicker/jquery.datetimepicker.css">
	
	<!-- <link href="./libs/bootstrap/dist/css/bootstrap.css" rel="stylesheet"> -->
	
	<!--  <script src="./libs/jquery/jquery.min.js"></script>--> 
	<script src="./static/fenix-spaces/js/jquery-ui.min.js"></script>
	<script src="./static/fenix-spaces/js/fullcalendar.min.js"></script>
	<script src="./static/fenix-spaces/js/moment.min.js"></script>
	<script src="./static/fenix-spaces/js/dateutils.js"></script>
	<script src="./static/fenix-spaces/js/jquery.datetimepicker.js"></script>
	<script src="./static/fenix-spaces/js/sprintf.min.js"></script>
</head>

<script>
	var date = new Date();
	var d = date.getDate();
	var m = date.getMonth();
	var y = date.getFullYear();
	var calendar = {
		header: {
			left: 'prev,next today',
			center: 'title',
			right: 'agendaWeek,month,year'
		},
		monthNames: ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'],
		monthNamesShort: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
		dayNames: ['Domingo', 'Segunda-Feira', 'Terça-Feira', 'Quarta-Feira', 'Quinta-Feira', 'Sexta-Feira', 'Sábado'],
		dayNamesShort: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'],
		buttonText: {
   			today:    'Hoje',
   			month:    'Mês',
   			week:     'Semana',
   			day:      'Ano'
		},
		timeFormat: { month: 'H:mm{ - H:mm}', '' : "H:mm" } ,
		columnFormat : {
   					month: 'ddd',    // Mon
   					week: 'ddd d/M', // Mon 9/7
   					day: 'dddd d/M'  // Monday 9/7
		},
		minTime : "08:00",
		maxTime : "24:00",
		axisFormat: 'H:mm',
		allDaySlot : false,
		editable: true,
		defaultView: "agendaWeek",
		firstDay: 1,
		editable: false,
		eventClick : function(event, jsEvent, view) {
			editEvent(event)
		}
	};

	var occupationEvents = {}
	var indexOccupationEvents = 1;

	function toggleCreator(state) {
		return function() {
			this.checked = state;
		}
	};

	var selectCheckbox = toggleCreator(true);
	var unselectCheckbox = toggleCreator(false);
	
	function weeklyClearAll() {
		$("#weekdays input").each(unselectCheckbox);
	}

	var repeatsconfig = {
		"w": {
			init: function() {
				var that = this;
	
				function selectDays(selector) {
					return function() {
						weeklyClearAll();
						if (selector) {
							$(selector).each(selectCheckbox);
						}
						that.updateSummary();
					}
				}
				$(".repeats").show();
	
				$("#weekdays input").click(function() {
					that.updateSummary();
				});
	
				$("#weekly-all").click(selectDays("#weekdays input"));
				$("#weekly-tue-thu").click(selectDays("#weekdays #tu,#weekdays #th"));
				$("#weekly-mon-wed-fri").click(selectDays("#weekdays #mo,#weekdays #we,#weekdays #fr"));
				$("#weekly-clear").click(selectDays());
			},
			html: "#weeklyrepeatson",
			label: "weeks",
			summary: "Weekly",
			updateSummary: function() {
				var selectedDays = []
				$("#weekdays input").each(function() {
					if (this.checked) {
						selectedDays.push($(this).attr('title'))
					}
				});
				var label = this['summary'];
				if (selectedDays.length > 0) {
					label += " on " + selectedDays.join(", ")
				}
				$("#summary").html(label)
			},
			processIntervals: function() {
				var occupation = this.getOccupation();
				var end = occupation.end
				var when = occupation.start.clone();
				var weekly = occupation.repeatsevery
				var weekdays = occupation.weekdays();
				var adjustWhen = function() {
					var found = 0
					$(weekdays).each(function(i, e) {
						if (e === when.isoWeekday()) {
							found = i;
							return false;
						}
					});
					var weekday = weekdays[found];
					when.isoWeekday(weekday)
					if (when.isBefore(occupation.start)) {
						when.add('weeks', 1)
					}
					return found;
				}
				var whenIndex = adjustWhen();
				var intervals = [];
				var i = whenIndex;
				while (when.isBefore(end) || when.isSame(end)) {
					var iStart = when.clone();
					var iEnd = when.clone();
					iEnd.hour(end.hour());
					iEnd.minute(end.minute());
					intervals.push({
						start: iStart,
						end: iEnd
					});
					if (i === weekdays.length - 1) {
						i = 0;
						when.add('weeks', 1);
					} else {
						i++;
					}
					var weekday = weekdays[i];
					when.isoWeekday(weekday);
				}
				return intervals;
			},
			getOccupation: function() {
				return {
					start: getStartMoment(),
					end: getEndMoment(),
					isAllDay: isAllDay(),
					repeatsevery: $("#repeatsevery").val(),
					frequency: $("#frequency").val(),
					title: $("#title").val(),
					weekdays : function() {
						var dict = { "mo" : 1, "tu" : 2, "we": 3 , "th" : 4 , "fr" : 5, "sa" : 6, "su": 7};
						return $("#weekdays input").filter(function() {
							return $(this).prop("checked");
						}).map(function() {
							return this.id;
						}).map(function() {
							return dict[this];
						});
					}
				}
			}
		},
	
		"d": {
			init: function() {
				$(".repeats").show();
			},
			html: undefined,
			label: "days",
			summary: "Daily",
			processIntervals: function() {
				var occupation = this.getOccupation();
				var start = occupation.start
				var end = occupation.end
				var daily = occupation.repeatsevery
				var when = start.clone();
				var intervals = [];
				while (when.isBefore(end) || when.isSame(end)) {
					var iStart = when.clone();
					var iEnd = when.clone();
					iEnd.hour(end.hour());
					iEnd.minute(end.minute());
					intervals.push({
						start: iStart,
						end: iEnd
					});
					when.add('days', daily);
				}
				return intervals;
			},
			getOccupation: function() {
				return {
					start: getStartMoment(),
					end: getEndMoment(),
					isAllDay: isAllDay(),
					repeatsevery: $("#repeatsevery").val(),
					frequency: $("#frequency").val(),
					title: $("#title").val()
				}
			}
		},
	
		"m": {
			init: function() {
				$(".repeats").show();
				var self = this;
				$("input:radio[name=monthly]").click(function() {
					self.updateSummary();
				})
			},
			html: "#monthlyrepeatson",
			label: "months",
			summary: "Monthly",
			updateSummary: function() {
				var startdate = moment($("#startdate").val(), "DD/MM/YYYY")
				var value = $("input:radio[name=monthly]:checked").val();
				if (value == "dayofmonth") {
					$("#summary").html(this["summary"] + " on day " + startdate.date());
				}
				if (value == "dayofweek") {
					$("#summary").html(this["summary"] + " on the " + nthDayOfTheWeekLabel(startdate) + " " + dayOfWeekLabel(startdate));
				}
			},
			getOccupation: function() {
				return {
					start: getStartMoment(),
					end: getEndMoment(),
					isAllDay: isAllDay(),
					repeatsevery: $("#repeatsevery").val(),
					title: $("#title").val(),
					monthlyType: $("input:radio[name=monthly]:checked").val()
				}
			},
			dayOfMonth : function(start, end, monthly) {
				var when = start.clone();
				var intervals = [];
				while (when.isBefore(end) || when.isSame(end)) {
					var iStart = when.clone();
					var iEnd = when.clone();
					iEnd.hour(end.hour());
					iEnd.minute(end.minute());
					intervals.push({
						start: iStart,
						end: iEnd
					});
					when.add('months', monthly);
				}
				return intervals;
			},
			dayOfWeek : function(start, end, monthly) {
				var nthDayOfWeek = nthdayOfTheWeek(start);
				var when = start.clone();
				var dayOfWeek = when.isoWeekday();
				var intervals = [];
				while (when.isBefore(end) || when.isSame(end)) {
					var iStart = when.clone();
					var iEnd = when.clone();
					iEnd.hour(end.hour());
					iEnd.minute(end.minute());
					intervals.push({
						start: iStart,
						end: iEnd
					});
					when.add('months', monthly)
					when = getNextNthdayOfWeek(when, nthDayOfWeek, dayOfWeek)
				}
				return intervals;
	
			},
			processIntervals: function() {
				var occupation = this.getOccupation();
				var start = occupation.start
				var end = occupation.end
				var monthly = occupation.repeatsevery
				if (occupation.monthlyType == "dayofmonth") {
					return this.dayOfMonth(start, end, monthly);
				}
				if (occupation.monthlyType == "dayofweek") {
					return this.dayOfWeek(start, end, monthly);
				}
			}
		},
	
		"n": {
			init: function() {
				$(".repeats").hide();
			},
			html: undefined,
			label: undefined,
			summary: "Never",
			getOccupation: function() {
				return {
					start: getStartMoment(),
					end: getEndMoment(),
					isAllDay: isAllDay(),
					repeatsevery: undefined,
					title: $("#title").val(),
				}
			},
			processIntervals: function() {
				var occupation = this.getOccupation();
				var start = occupation.start
				var end = occupation.end
				var intervals = [];
				intervals.push({ start : occupation.start, end: occupation.end})
				return intervals;
			}
		},
	
		"y": {
			init: function() {
				$(".repeats").show();
			},
			html: undefined,
			label: "years",
			summary: "Yearly",
			getOccupation: function() {
				return {
					start: getStartMoment(),
					end: getEndMoment(),
					isAllDay: isAllDay(),
					repeatsevery: $("#repeatsevery").val(),
					title: $("#title").val(),
				}
			},
			processIntervals: function() {
				var occupation = this.getOccupation();
				var start = occupation.start
				var end = occupation.end
				var yearly = occupation.repeatsevery
				var when = start.clone();
				var intervals = [];
				while (when.isBefore(end) || when.isSame(end)) {
					var iStart = when.clone();
					var iEnd = when.clone();
					iEnd.hour(end.hour());
					iEnd.minute(end.minute());
					intervals.push({
						start: iStart,
						end: iEnd
					});
					when.add('years', yearly);
				}
				return intervals;
			}
		}
	};

	function addEvent(interval, occupation) {
		var occupationEvent;
		if (occupation.isAllDay) {
			occupationEvent = {
				id : occupation.id,
				start:interval.start.format("X"),
				end: interval.start.format("X"),
				allDay:false,
				title:occupation.title
			};
		} else {
			occupationEvent = {
				id : occupation.id,
				allDay: false,
				title: occupation.title,
				start: interval.start.format("X"),
				end: interval.end.format("X")
			};
		}
		$('#calendar').fullCalendar('renderEvent', occupationEvent, true);
	}
	
	function editEvent(calendarEvent) {
		var event = occupationEvents[calendarEvent.id];
		$("#startdate").val(event.start.format("DD/MM/YYYY"));
		$("#enddate").val(event.end.format("DD/MM/YYYY"));
		$("#starttime").val(event.start.format("HH:mm"));
		$("#endtime").val(event.end.format("HH:mm"));
		if (event.isAllDay) {
			$("#allday").click();
		}
		$("#repeatsevery").val(event.repeatsevery)
		$("#frequency").val(event.frequency);
		$("#title").val(event.title);
		$("#myModal").data("event", calendarEvent.id);
		$("#delete").show();
		$("#myModal").modal("show");
	}

	$(document).ready(function() {
		
		$('#calendar').fullCalendar(calendar);

		var datepickerConfig = { format : "d/m/Y", 
				  mask: true, 
				  timepicker : false,
				  value : moment().format("DD/MM/YYYY"),
				  onSelectDate: function(current,$input){
				  					var config = repeatsconfig[$("#frequency").val()];
				  					if (config.updateSummary) {
				  						config.updateSummary();
				  					}
								}
				};

		$("#startdate").datetimepicker(datepickerConfig);

		datepickerConfig.value = null;

		$("#enddate").datetimepicker(datepickerConfig);


		var timepickerConfig = { format : "H:i", mask: true, datepicker : false, step:30};

		$("#starttime,#endtime").datetimepicker(timepickerConfig);

		$("#add-event").click(function() {
			$("#delete").hide();
			$("#myModal").modal("show");
		});

		$(".repeats").hide();

		$("#allday").change(function() {
			if (this.checked) {
				$("#starttime").hide();
				$("#endtime").hide();
			}else {
				$("#starttime").show();
				$("#endtime").show();
			}
		});

		$("#frequency").change(function() {
			var val = $(this).val();
			$("#repeatsconfig").empty();
			var config = repeatsconfig[val];
			var html = config['html'];
			var label = config['label'];
			var summary = config['summary'];
			if (html) {
				$("#repeatsconfig").html($(html).html())	
			}
			if (label) {
				$("#repeatsevery-label").html(label);
			}
			if (summary) {
				$("#summary").html(summary);
			}
			config.init();
		});

		// init repeatsevery options
		for (var i = 1; i <= 30; i++) {
			$("#repeatsevery").append(sprintf("<option value='%1$s'>%1$s</option>", i));
		}

		$("#save").click(function() {
			var event_id = $("#myModal").data("event")
			var config = repeatsconfig[$("#frequency").val()];
			var occupation = config.getOccupation();
			
			if (!isNaN(event_id)) {
				$("#calendar").fullCalendar('removeEvents', event_id)
				occupation.id = event_id;
			} else {
				occupation.id = indexOccupationEvents++;
			}

			occupationEvents[occupation.id] = occupation;
			$(config.processIntervals()).each(function() {
				addEvent(this, occupation);
			});

			$("#myModal").removeData("event")
			$("#myModal").modal("hide");
		});

		$("#delete").click(function() {
			var event_id = $("#myModal").data("event");
			delete occupationEvents[event_id];
			$("#calendar").fullCalendar('removeEvents', event_id);
			$("#myModal").modal('hide');
		});

		/** init code **/
		$("#frequency option[value=w]").prop('selected', true);
		$("#repeatsevery option[value=1]").select();
		$("#frequency").change();
		$("#mo, #we").click();
		$("#delete").hide();
	});
</script>
	
<script type="text/html" id="weeklyrepeatson">
<th class="col-lg-3">Repeat on</th>
<td class="col-lg-9">
	<span id="weekdays">
		<input id="mo" type="checkbox" title="Monday">
		<span title="Monday">M</span>
		<input id="tu" type="checkbox" title="Tuesday">
		<span title="Tuesday">T</span>
		<input id="we" type="checkbox" title="Wednesday">
		<span title="Wednesday">W</span>
		<input id="th" type="checkbox" title="Thursday">
		<span title="Thursday">T</span>
		<input id="fr" type="checkbox" title="Friday">
		<span title="Friday">F</span>
		<input id="sa" type="checkbox" title="Saturday">
		<span title="Saturday">S</span>
		<input id="su" type="checkbox" title="Sunday">
		<span title="Sunday">S</span>
	</span>
	<span style="display: block;">
		<button class="btn btn-xs btn-success" id="weekly-all">all</button>
		<button class="btn btn-xs btn-success" id="weekly-tue-thu">3 e 5</button>
		<button class="btn btn-xs btn-success" id="weekly-mon-wed-fri">2,4 e 6</button>
		<button class="btn btn-xs btn-success" id="weekly-clear">clear</button>
	</span>
</td>			
</script>

<script type="text/html" id="monthlyrepeatson">
<th class="col-lg-3">Repeat by</th>
<td class="col-lg-9">
	<span id="options">
		<input type="radio" name="monthly" value="dayofmonth" checked/>
		<span>day of the month</span>
		<input type="radio" name="monthly" value="dayofweek"/>
		<span>day of the week</span>
	</span>
</td>			
</script>

<style>
body {
	margin-top: 40px;
	text-align: center;
	font-size: 14px;
	font-family: "Lucida Grande",Helvetica,Arial,Verdana,sans-serif;
}

#calendar {
	width: 900px;
	margin: 0 auto;
}
</style>


<body>
	<div id="calendar"></div>
	
	<!-- Button trigger modal -->
	<button class="btn btn-primary btn-lg" id="add-event">
		Add Event
	</button>

	<!-- Modal -->
	<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  		<div class="modal-dialog">
			<div class="modal-content">
				<div class="modal-header">
		        	<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
		        	<h4 class="modal-title" id="myModalLabel">Modal title</h4>
		      	</div>
				<div class="modal-body">
		        	<table class="table" id="create-event">
			        	<tr class="row">
							<th class="col-lg-3">Title</th>
							<td class="col-lg-9">
								<input type="textarea" id="title" value="zen"/>
							</td>
						</tr>
						<tr class="row">
							<th class="col-lg-3">Start</th>
							<td>
								<span style="display:block;">
									<input type="text" id="startdate" value="07/03/2014"/>
								</span>
							</td>
						</tr>
						<tr class="row">
							<th class="col-lg-3">Ends</th>
							<td class="col-lg-9">
								
								<span style="display:block;">
									<input type="text" id="enddate" value="20/05/2014"/>
								</span>
								
							</td>
						</tr>
						<tr class="row">
							<th class="col-lg-3">All day</th>
							<td class="col-lg-9">
								<input type="checkbox" id="allday"/>
								<span style="display:block;">
										<input type="text" id="starttime" value="14:00"/>
									</span>
									<span>
										<input type="text" id="endtime" value="16:00"/>
									</span>
								</td>
							</tr>
							<tr class="row">
								<th class="col-lg-3">Repeats</th>
								<td class="col-lg-9">
									<select id="frequency">
										<option value="n">Never</option>
										<option value="d">Daily</option>
										<option value="w">Weekly</option>
										<option value="m">Monthy</option>
										<option value="y">Yearly</option>
									</select>
								</td>
							</tr>
							<tr class="repeats row">
								<th class="col-lg-3">Repeats every</th>
								<td class="col-lg-9">
									<select name="" id="repeatsevery">
									</select>
									<label id="repeatsevery-label">days</label>
								</td>
							</tr>
							<tr id="repeatsconfig" class="repeats row">
							</tr>
							<tr class="row">
								<th class="col-lg-2">Summary</th>
								<td class="col-lg-9" id="summary"></td>
							</tr>
					</table>
				</div>
			    <div class="modal-footer">
			      <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
			      <button type="button" id="delete" class="btn btn-danger">Delete</button>
			      <button type="button" class="btn btn-primary" id="save">Save changes</button>
			    </div>
    		</div>
	  	</div>
	</div>
	
</body></html>

