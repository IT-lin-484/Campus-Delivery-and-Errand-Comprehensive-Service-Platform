package com.campusrunner.backend.admin.dao;

import java.util.Optional;

import com.campusrunner.backend.admin.entity.SystemConfig;
import com.campusrunner.backend.common.dao.BaseDao;

/**
 * System config data access interface.
 */
public interface SystemConfigDao extends BaseDao<SystemConfig> {

    Optional<SystemConfig> findTopByOrderByIdAsc();
}
