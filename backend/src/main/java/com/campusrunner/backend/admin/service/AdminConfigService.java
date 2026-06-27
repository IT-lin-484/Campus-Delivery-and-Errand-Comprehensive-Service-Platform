package com.campusrunner.backend.admin.service;

import com.campusrunner.backend.admin.dto.AdminConfigResponse;
import com.campusrunner.backend.admin.dto.AdminUpdateConfigRequest;
import com.campusrunner.backend.admin.entity.AdminAuditLog;
import com.campusrunner.backend.admin.entity.SystemConfig;
import com.campusrunner.backend.admin.dao.AdminAuditLogDao;
import com.campusrunner.backend.admin.dao.SystemConfigDao;

public interface AdminConfigService {
    AdminConfigResponse getConfig();
    AdminConfigResponse updateConfig(Long adminId, AdminUpdateConfigRequest request);
}

