package com.campusrunner.backend.admin.dao;

import org.apache.ibatis.annotations.Param;

import com.campusrunner.backend.admin.entity.AdminReport;
import com.campusrunner.backend.admin.enums.AdminReportStatus;
import com.campusrunner.backend.common.dao.BaseDao;

/**
 * Admin report data access interface.
 */
public interface AdminReportDao extends BaseDao<AdminReport> {

    long countByStatus(@Param("status") AdminReportStatus status);
}
