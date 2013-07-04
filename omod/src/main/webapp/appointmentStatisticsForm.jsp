<%@ include file="/WEB-INF/template/include.jsp"%>

<%@ include file="/WEB-INF/template/header.jsp"%>
<%@ include file="localHeader.jsp"%>


<openmrs:htmlInclude file="/moduleResources/appointmentscheduling/Scripts/timepicker.js" />
<openmrs:htmlInclude file="/moduleResources/appointmentscheduling/Scripts/date.format.js" />
<openmrs:htmlInclude file="/moduleResources/appointmentscheduling/Scripts/jquery.jqplot.min.js" />
<openmrs:htmlInclude file="/moduleResources/appointmentscheduling/Scripts/jqPlot-plugins/jqplot.pointLabels.min.js" />
<openmrs:htmlInclude file="/moduleResources/appointmentscheduling/Scripts/jqPlot-plugins/jqplot.barRenderer.min.js" />
<openmrs:htmlInclude file="/moduleResources/appointmentscheduling/Scripts/jqPlot-plugins/jqplot.categoryAxisRenderer.min.js" />
<openmrs:htmlInclude file="/moduleResources/appointmentscheduling/Scripts/jqPlot-plugins/jqplot.donutRenderer.min.js" />
<openmrs:htmlInclude file="/moduleResources/appointmentscheduling/Scripts/jqPlot-plugins/jqplot.pieRenderer.min.js" />

<openmrs:htmlInclude file="/moduleResources/appointmentscheduling/Styles/jquery.jqplot.min.css" />
<openmrs:htmlInclude file="/moduleResources/appointmentscheduling/Styles/appointmentStatisticsStyle.css" />

<openmrs:require privilege="View Appointments Statistics" otherwise="/login.htm" redirect="/module/appointmentscheduling/appointmentStatisticsForm.form" />


<script type="text/javascript"
	src='${pageContext.request.contextPath}/dwr/engine.js'></script>
<script type="text/javascript"
	src='${pageContext.request.contextPath}/dwr/util.js'></script>
<script type="text/javascript"
	src='${pageContext.request.contextPath}/dwr/interface/DWRAppointmentService.js'></script>
	
<script type="text/javascript">

var openTab = "";

$j(document)
	.ready(
			function() {		
				
				//Init Dates FIltering
				InitDateFilter();
				//Prevent date keyboard input
				$j("#fromDate").keypress(function(event) {event.preventDefault();});
				$j("#toDate").keypress(function(event) {event.preventDefault();});
				
				//Init Accordion
				$j("#plots").accordion({
					collapsible: true,
					active: false
				});
				 
				$j('#plots').bind('accordionchange', function(event, ui) {
					openTab = $j(ui.newContent).attr('id');
					UpdateData(openTab);
				});
			}); //END Of .ready


//Init default dates to current day
function InitDateFilter(){
 	if(document.getElementById('fromDate').value == "" && document.getElementById('toDate').value == ""){	
 		//Set to first day of month 00:00:00.000
        var todayStart = new Date();
        todayStart.setDate(1);
        todayStart.setHours(0,0,0,0);
        
      	//Set to last day of month 23:59:59.999
        var todayEnd = new Date();
        todayEnd.setHours(23,59,59,999);
        todayEnd.setDate(new Date(todayStart.getFullYear(), todayStart.getMonth() + 1, 0, 23, 59, 59).getDate());

        
     
		var locale = '${locale}';

		if(locale=='en_US'){
			var timeFormat = jsTimeFormat.replace('mm','MM');
			document.getElementById('fromDate').value = todayStart.format(jsDateFormat+' '+timeFormat);
			document.getElementById('toDate').value = todayEnd.format(jsDateFormat+' '+timeFormat);
		}
		else{
			document.getElementById('fromDate').value = todayStart.format(jsDateFormat+' HH:MM');
			document.getElementById('toDate').value = todayEnd.format(jsDateFormat+' HH:MM');
			
		}
	}
}

//Update the graphs according to the new data date range.
function UpdateData(container){
	if(!container)
		return;
	else if(container=="waitingContainer")
		waitingTime();
	else if(container=="consultationContainer")
		consultationDuration();
	else if(container=="typeContainer")
		typeDistribution();
	else if(container=="waitingProviderContainer")
		waitingProviderTime();
	else if(container=="consultationProviderContainer")
		consultationProviderDuration();
}


// Update Waiting Time by Appointment Type plot - ID: waitingContainer
function waitingTime(){
	//reset plot
	document.getElementById('waitingPlot').innerHTML = "";
	
	//update counter
	var fromDate = document.getElementById('fromDate').value;
	var toDate = document.getElementById('toDate').value;

	DWRAppointmentService
			.getCountOfWaitingHistories(
					fromDate, toDate,
					function(result) {
						if(result>0)
							document.getElementById('waitingDatasize').innerHTML = "<spring:message code='appointmentscheduling.Appointment.statistics.label.dataSize' arguments='"+result+"' />";
						else
							document.getElementById('waitingDatasize').innerHTML = "<spring:message code='appointmentscheduling.Appointment.statistics.label.dataEmpty' />";
					});
	
	//update plot
		DWRAppointmentService
			.getAverageWaitingTimeByType(
					fromDate, toDate,
					function(result) {
						if(result.length==0){
							document.getElementById('waitingPlot').display = 'none';
							return;
						}
						document.getElementById('waitingPlot').display = 'table';
						document.getElementById('waitingPlot').width = '100%';
						var series = new Array();
						var seriesLabels = new Array();
						var ticks = ['<spring:message code="appointmentscheduling.Appointment.statistics.axis.appointmentType" />'];
						for(i=0;i<result.length;i++){
							seriesLabels[i] = {label:result[i][0]};
							series[i] = [Number(result[i][1])];
						}

						var waitingPlot = $j.jqplot('waitingPlot', series, {
								title: "<spring:message code='appointmentscheduling.Appointment.statistics.title.waitingTime'/>",
								seriesDefaults:{
									renderer:$j.jqplot.BarRenderer,
									rendererOptions: {fillToZero: true, barPadding:12, barWidth:80},
									pointLabels: { show: true, location: 'n', edgeTolerance: -15, formatString: '%#.2f <spring:message code="appointmentscheduling.Appointment.statistics.label.minute" />' },
								},
								series:seriesLabels,
								legend: {
									show: true,
									placement: 'outsideGrid'
								},
								axes: {
									xaxis: {
										renderer:$j.jqplot.CategoryAxisRenderer,
										ticks: ticks
									},
									yaxis: {
										pad:1.05,
										min:0,
										label:'<spring:message code="appointmentscheduling.Appointment.statistics.label.minute" />'
									}
								}
							});
					});
}

// Update Consultation Duration by Appointment Type plot - ID: consultationContainer
function consultationDuration(){
	//reset plot
	document.getElementById('consultationPlot').innerHTML = "";
	
	//update count
	var fromDate = document.getElementById('fromDate').value;
	var toDate = document.getElementById('toDate').value;
	
	DWRAppointmentService
		.getCountOfConsultationHistories(
				fromDate, toDate,
				function(result) {
					if(result>0)
						document.getElementById('consultationDatasize').innerHTML = "<spring:message code='appointmentscheduling.Appointment.statistics.label.dataSize' arguments='"+result+"' />";
					else
						document.getElementById('consultationDatasize').innerHTML = "<spring:message code='appointmentscheduling.Appointment.statistics.label.dataEmpty' />";
				});
	
	//update plot
	DWRAppointmentService
		.getAverageConsultationTimeByType(
				fromDate, toDate,
				function(result) {
					if(result.length==0){
						document.getElementById('consultationContainer').display = 'none';
						return;
					}
					var series = new Array();
					var seriesLabels = new Array();
					var ticks = ['<spring:message code="appointmentscheduling.Appointment.statistics.axis.appointmentType" />'];
					
					for(i=0;i<result.length;i++){
						seriesLabels[i] = {label:result[i][0]};
						series[i] = [Number(result[i][1])];
					}

					var consultationPlot = $j.jqplot('consultationPlot', series, {
							title: "<spring:message code='appointmentscheduling.Appointment.statistics.title.consultationDuration'/>",
							seriesDefaults:{
								renderer:$j.jqplot.BarRenderer,
								rendererOptions: {fillToZero: true, barPadding:12, barWidth:80},
								pointLabels: { show: true, location: 'n', edgeTolerance: -15, formatString: '%#.2f <spring:message code="appointmentscheduling.Appointment.statistics.label.minute" />' },
							},
							series:seriesLabels,
							legend: {
								show: true,
								placement: 'outsideGrid'
							},
							axes: {
								xaxis: {
									renderer:$j.jqplot.CategoryAxisRenderer,
									ticks: ticks
								},
								yaxis: {
									pad:1.05,
									min:0,
									label:'<spring:message code="appointmentscheduling.Appointment.statistics.label.minute" />'
								}
							}
						});
				});
}

// Update Appointment Type Distribution plot - ID: typeContainer
function typeDistribution(){
	//reset plot
	document.getElementById('typePlot').innerHTML = "";
	
	//update count
	var fromDate = document.getElementById('fromDate').value;
	var toDate = document.getElementById('toDate').value;
	
	DWRAppointmentService
		.getAppointmentsCount(
				fromDate, toDate,
				function(result) {
					if(result>0)
						document.getElementById('typeDatasize').innerHTML = "<spring:message code='appointmentscheduling.Appointment.statistics.label.dataSize' arguments='"+result+"' />";
					else
						document.getElementById('typeDatasize').innerHTML = "<spring:message code='appointmentscheduling.Appointment.statistics.label.dataEmpty' />";
				});
				
	//update plot
	DWRAppointmentService
			.getAppointmentTypeDistribution(
					fromDate, toDate,
					function(result) {
						var resultSum = 0;
						for(var i=0; i<result.length; i++)
							resultSum += result[i][1];
						if(resultSum==0){
							document.getElementById('typeContainer').display = 'none';
							return;
						}
						document.getElementById('typePlot').display = 'table';
						var typePlot = $j.jqplot('typePlot', [result], {
								title: "<spring:message code='appointmentscheduling.Appointment.statistics.title.typePie'/>",
								seriesDefaults: {
									// Make this a pie chart.
									renderer: jQuery.jqplot.PieRenderer, 
									rendererOptions: {
									  // Put data labels on the pie slices.
									  // By default, labels show the percentage of the slice.
									  showDataLabels: true
									}
								 }, 
								 legend: { show:true, location: 'e' }
							});
					});
}

// Update Waiting Time by Provider plot - ID: waitingProviderContainer
function waitingProviderTime(){
	//reset plot
	document.getElementById('waitingProviderPlot').innerHTML = "";
					
	//update count
	var fromDate = document.getElementById('fromDate').value;
	var toDate = document.getElementById('toDate').value;
		
	DWRAppointmentService
			.getCountOfWaitingHistories(
					fromDate, toDate,
					function(result) {
						if(result>0)
							document.getElementById('waitingProviderDatasize').innerHTML = "<spring:message code='appointmentscheduling.Appointment.statistics.label.dataSize' arguments='"+result+"' />";
						else
							document.getElementById('waitingProviderDatasize').innerHTML = "<spring:message code='appointmentscheduling.Appointment.statistics.label.dataEmpty' />";
					});
	
	//update plot
	DWRAppointmentService
			.getAverageWaitingTimeByProvider(
					fromDate, toDate,
					function(result) {
						if(result.length==0){
							document.getElementById('waitingProviderPlot').display = 'none';
							return;
						}
						document.getElementById('waitingProviderPlot').display = 'table';
						document.getElementById('waitingProviderPlot').width = '100%';
						var series = new Array();
						var seriesLabels = new Array();
						var ticks = ['<spring:message code="appointmentscheduling.Appointment.statistics.axis.provider" />'];
						for(i=0;i<result.length;i++){
							seriesLabels[i] = {label:result[i][0]};
							series[i] = [Number(result[i][1])];
						}

						var waitingProviderPlot = $j.jqplot('waitingProviderPlot', series, {
								title: "<spring:message code='appointmentscheduling.Appointment.statistics.title.waitingProviderTime'/>",
								seriesDefaults:{
									renderer:$j.jqplot.BarRenderer,
									rendererOptions: {fillToZero: true, barPadding:12, barWidth:80},
									pointLabels: { show: true, location: 'n', edgeTolerance: -15, formatString: '%#.2f <spring:message code="appointmentscheduling.Appointment.statistics.label.minute" />' },
								},
								series:seriesLabels,
								legend: {
									show: true,
									placement: 'outsideGrid'
								},
								axes: {
									xaxis: {
										renderer:$j.jqplot.CategoryAxisRenderer,
										ticks: ticks
									},
									yaxis: {
										pad:1.05,
										min:0,
										label:'<spring:message code="appointmentscheduling.Appointment.statistics.label.minute" />'
									}
								}
							});
					});
}

// Update Consultation Duration by Provider plot - ID: waitingProviderContainer
function consultationProviderDuration(){
	//reset plot
	document.getElementById('consultationProviderPlot').innerHTML = "";

	//update count
	var fromDate = document.getElementById('fromDate').value;
	var toDate = document.getElementById('toDate').value;
	
	DWRAppointmentService
		.getCountOfConsultationHistories(
				fromDate, toDate,
				function(result) {
					if(result>0)
						document.getElementById('consultationProviderDatasize').innerHTML = "<spring:message code='appointmentscheduling.Appointment.statistics.label.dataSize' arguments='"+result+"' />";
					else
						document.getElementById('consultationProviderDatasize').innerHTML = "<spring:message code='appointmentscheduling.Appointment.statistics.label.dataEmpty' />";
				});

	//update plot
	DWRAppointmentService
			.getAverageConsultationTimeByProvider(
					fromDate, toDate,
					function(result) {
						if(result.length==0){
							document.getElementById('consultationProviderContainer').display = 'none';
							return;
						}
						var series = new Array();
						var seriesLabels = new Array();
						var ticks = ['<spring:message code="appointmentscheduling.Appointment.statistics.axis.provider" />'];
						
						for(i=0;i<result.length;i++){
							seriesLabels[i] = {label:result[i][0]};
							series[i] = [Number(result[i][1])];
						}

						var consultationProviderPlot = $j.jqplot('consultationProviderPlot', series, {
								title: "<spring:message code='appointmentscheduling.Appointment.statistics.title.consultationProviderDuration'/>",
								seriesDefaults:{
									renderer:$j.jqplot.BarRenderer,
									rendererOptions: {fillToZero: true, barPadding:12, barWidth:80},
									pointLabels: { show: true, location: 'n', edgeTolerance: -15, formatString: '%#.2f <spring:message code="appointmentscheduling.Appointment.statistics.label.minute" />' },
								},
								series:seriesLabels,
								legend: {
									show: true,
									placement: 'outsideGrid'
								},
								axes: {
									xaxis: {
										renderer:$j.jqplot.CategoryAxisRenderer,
										ticks: ticks
									},
									yaxis: {
										pad:1.05,
										min:0,
										label:'<spring:message code="appointmentscheduling.Appointment.statistics.label.minute" />'
									}
								}
							});
					});
}
</script>
</script>
</script>


<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>


<h2 id="headline">
	<spring:message code="appointmentscheduling.Appointment.statistics.title" />
</h2>

<b class="boxHeader"><spring:message
		code="appointmentscheduling.Appointment.statistics.title.filter" /></b>
<fieldset>
<table>
	<tr>
		<td class="formLabel"><spring:message
				code="appointmentscheduling.Appointment.statistics.datesFilter" /></td>
		<td><input type="text" name="fromDate" id="fromDate" size="18"
			value="${param.fromDate}" onfocus="showDateTimePicker(this)" /> <img
			src="${pageContext.request.contextPath}/moduleResources/appointmentscheduling/Images/calendarIcon.png"
			class="calendarIcon" alt=""
			onClick="document.getElementById('fromDate').focus();" /> and <input
			type="text" name="toDate" id="toDate" size="18"
			value="${param.toDate}" onfocus="showEndDateTimePicker(this)"//> <img
			src="${pageContext.request.contextPath}/moduleResources/appointmentscheduling/Images/calendarIcon.png"
			class="calendarIcon" alt=""
			onClick="document.getElementById('toDate').focus();"></td>
	</tr>
	<tr><td></td><td style="float:right;margin:15px;">
		<input type="button" value="<spring:message code='general.submit' />" onclick="UpdateData(openTab);"/>
	</td></tr>
</table>
</fieldset>
<div id="accordionContainer">
	<div id="plots">
		<!-- Waiting Time by Appointment Type -->
		<h3><spring:message code='appointmentscheduling.Appointment.statistics.title.waitingTime'/></h3>
		<div id="waitingContainer" class="plotContainer">
		<div id='waitingDatasize'></div>
		<center><div id="waitingPlot" style="height:460px !important;width:100% !important; "></div></center>
		</div>

		<!-- Consultation Duration by Appointment Type -->
		<h3><spring:message code='appointmentscheduling.Appointment.statistics.title.consultationDuration'/></h3>
		<div id="consultationContainer" class="plotContainer">
		<div id='consultationDatasize'></div>
		<center><div id="consultationPlot" style="height:460px !important;width:100% !important; "></div></center>
		</div>

		<!-- Appointment Type Pie Chart -->
		<h3><spring:message code='appointmentscheduling.Appointment.statistics.title.typePie'/></h3>
		<div id="typeContainer" class="plotContainer">
		<div id='typeDatasize'></div>
		<center><div id="typePlot" style="height:460px !important;width:100% !important; "></div></center>
		</div>

		<!-- Waiting Time by Provider -->
		<h3><spring:message code='appointmentscheduling.Appointment.statistics.title.waitingTime'/></h3>
		<div id="waitingProviderContainer" class="plotContainer">
		<div id='waitingProviderDatasize'></div>
		<center><div id="waitingProviderPlot" style="height:460px !important;width:100% !important; "></div></center>
		</div>

		<!-- Consultation Duration by Provider -->
		<h3><spring:message code='appointmentscheduling.Appointment.statistics.title.consultationDuration'/></h3>
		<div id="consultationProviderContainer" class="plotContainer">
		<div id='consultationProviderDatasize'></div>
		<center><div id="consultationProviderPlot" style="height:460px !important;width:100% !important; "></div></center>
		</div>
	</div>
</div>
<%@ include file="/WEB-INF/template/footer.jsp"%>