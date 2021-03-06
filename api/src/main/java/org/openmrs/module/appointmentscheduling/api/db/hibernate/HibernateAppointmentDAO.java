/**
 * The contents of this file are subject to the OpenMRS Public License
 * Version 1.0 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://license.openmrs.org
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 * Copyright (C) OpenMRS, LLC.  All Rights Reserved.
 */
package org.openmrs.module.appointmentscheduling.api.db.hibernate;

import java.util.Calendar;
import java.util.Date;
import java.util.List;

import org.hibernate.Query;
import org.hibernate.criterion.Restrictions;
import org.openmrs.Location;
import org.openmrs.Patient;
import org.openmrs.Provider;
import org.openmrs.Visit;
import org.openmrs.api.APIException;
import org.openmrs.module.appointmentscheduling.Appointment;
import org.openmrs.module.appointmentscheduling.AppointmentType;
import org.openmrs.module.appointmentscheduling.TimeSlot;
import org.openmrs.module.appointmentscheduling.Appointment.AppointmentStatus;
import org.openmrs.module.appointmentscheduling.api.db.AppointmentDAO;
import org.springframework.transaction.annotation.Transactional;

public class HibernateAppointmentDAO extends HibernateSingleClassDAO implements AppointmentDAO {
	
	public HibernateAppointmentDAO() {
		super(Appointment.class);
	}
	
	@Override
	@Transactional(readOnly = true)
	public List<Appointment> getAppointmentsByPatient(Patient patient) {
		return super.sessionFactory.getCurrentSession().createCriteria(Appointment.class)
		        .add(Restrictions.eq("patient", patient)).list();
	}
	
	@Override
	@Transactional(readOnly = true)
	public Appointment getAppointmentByVisit(Visit visit) {
		return (Appointment) super.sessionFactory.getCurrentSession()
		        .createQuery("from " + mappedClass.getSimpleName() + " at where at.visit = :visit")
		        .setParameter("visit", visit).uniqueResult();
	}
	
	@Override
	@Transactional(readOnly = true)
	public Appointment getLastAppointment(Patient patient) {
		String query = "select appointment from Appointment as appointment"
		        + " where appointment.patient = :patient and appointment.timeSlot.startDate ="
		        + " (select max(timeSlot.startDate) from Appointment as appointment inner join appointment.timeSlot"
		        + " where appointment.patient = :patient)";
		
		List<Appointment> appointment = super.sessionFactory.getCurrentSession().createQuery(query)
		        .setParameter("patient", patient).list();
		
		if (appointment.size() > 0)
			return (Appointment) appointment.get(0);
		else
			return null;
	}
	
	@Override
	@Transactional(readOnly = true)
	public List<Appointment> getAppointmentsByConstraints(Date fromDate, Date toDate, Provider provider,
	        AppointmentType appointmentType, AppointmentStatus status) throws APIException {
		if (fromDate != null && toDate != null && !fromDate.before(toDate))
			throw new APIException("fromDate can not be later than toDate");
		
		else {
			String stringQuery = "SELECT appointment FROM Appointment AS appointment WHERE appointment.voided = 0";
			
			if (fromDate != null)
				stringQuery += " AND appointment.timeSlot.startDate >= :fromDate";
			if (toDate != null)
				stringQuery += " AND appointment.timeSlot.endDate <= :endDate";
			if (provider != null)
				stringQuery += " AND appointment.timeSlot.appointmentBlock.provider = :provider";
			if (status != null)
				stringQuery += " AND appointment.status=:status";
			if (appointmentType != null)
				stringQuery += " AND appointment.appointmentType=:appointmentType";
			
			Query query = super.sessionFactory.getCurrentSession().createQuery(stringQuery);
			
			if (fromDate != null)
				query.setParameter("fromDate", fromDate);
			if (toDate != null)
				query.setParameter("endDate", toDate);
			if (provider != null)
				query.setParameter("provider", provider);
			if (status != null)
				query.setParameter("status", status);
			if (appointmentType != null)
				query.setParameter("appointmentType", appointmentType);
			
			return query.list();
		}
	}
	
	@Override
	@Transactional(readOnly = true)
	public List<Appointment> getAppointmentsByStates(List<AppointmentStatus> states) {
		String sQuery = "from Appointment as appointment where appointment.voided = 0 and appointment.status in (:states)";
		
		Query query = super.sessionFactory.getCurrentSession().createQuery(sQuery);
		query.setParameterList("states", states);
		
		return query.list();
	}
	
	@Override
	@Transactional(readOnly = true)
	public List<Appointment> getPastAppointmentsByStates(List<AppointmentStatus> states) {
		String sQuery = "from Appointment as appointment where appointment.timeSlot.endDate <= :endDate and appointment.voided = 0 and appointment.status in (:states)";
		
		Query query = super.sessionFactory.getCurrentSession().createQuery(sQuery);
		query.setParameterList("states", states);
		query.setParameter("endDate", Calendar.getInstance().getTime());
		
		return query.list();
	}
}
