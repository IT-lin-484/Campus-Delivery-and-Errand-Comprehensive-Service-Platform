package com.campusrunner.backend.admin.service;

import java.util.List;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.admin.dto.AdminAuditLogListResponse;
import com.campusrunner.backend.admin.dto.AdminAuditLogResponse;
import com.campusrunner.backend.admin.entity.AdminAuditLog;
import com.campusrunner.backend.admin.dao.AdminAuditLogDao;

public interface AdminAuditService {
    AdminAuditLogListResponse listLogs(String action, String targetType, Long operatorId, int page, int pageSize);
}

