/*
 Navicat Premium Data Transfer

 Source Server         : 127.0.0.1
 Source Server Type    : MySQL
 Source Server Version : 50744
 Source Host           : localhost:3306
 Source Schema         : study_room_booking

 Target Server Type    : MySQL
 Target Server Version : 50744
 File Encoding         : 65001

 Date: 17/12/2025 10:29:29
*/

-- ===================================================================
-- 大学生自习室预约系统 - 数据库初始化脚本
-- ===================================================================
-- 说明：
--   本文件包含系统的完整数据库结构、初始数据和业务逻辑对象。
--   可直接导入 MySQL 5.7+ 完成数据库初始化。
--
-- 业务表概览：
--   accounts_user        - 用户表（扩展 Django AbstractUser）
--   accounts_blacklist   - 黑名单表（封禁记录）
--   rooms_studyroom      - 自习室表
--   rooms_seat           - 座位表
--   bookings_booking     - 预约表
--
-- Django 框架表（自动生成）：
--   auth_group / auth_permission / django_content_type / django_migrations / django_session 等
-- ===================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ===================================================================
-- 第1部分：用户与权限相关表
-- ===================================================================

-- ============================================================
-- 表：accounts_blacklist（黑名单表）
-- 说明：记录用户被封禁的历史，支持解封
-- 关联：user_id → accounts_user.id
--       banned_by_id → accounts_user.id（操作管理员）
-- ============================================================
DROP TABLE IF EXISTS `accounts_blacklist`;
CREATE TABLE `accounts_blacklist`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `reason` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '封禁原因',
  `banned_at` datetime(6) NOT NULL COMMENT '封禁时间',
  `unbanned_at` datetime(6) NULL DEFAULT NULL COMMENT '解封时间',
  `is_active` tinyint(1) NOT NULL COMMENT '是否生效中',
  `banned_by_id` bigint(20) NULL DEFAULT NULL COMMENT '操作管理员ID',
  `user_id` bigint(20) NOT NULL COMMENT '被封禁用户ID',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `accounts_blacklist_banned_by_id_bd5b30d1_fk_accounts_user_id`(`banned_by_id`) USING BTREE,
  INDEX `accounts_blacklist_user_id_c51c78f1_fk_accounts_user_id`(`user_id`) USING BTREE,
  CONSTRAINT `accounts_blacklist_banned_by_id_bd5b30d1_fk_accounts_user_id` FOREIGN KEY (`banned_by_id`) REFERENCES `accounts_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `accounts_blacklist_user_id_c51c78f1_fk_accounts_user_id` FOREIGN KEY (`user_id`) REFERENCES `accounts_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- 黑名单示例数据（5条）：
--   前3条为历史记录（已解封），后2条为当前生效的封禁
INSERT INTO `accounts_blacklist` VALUES (1, '连续3次预约未到场', '2025-03-15 10:00:00.000000', '2025-04-15 10:00:00.000000', 0, 1, 2);
INSERT INTO `accounts_blacklist` VALUES (2, '在自习室内吸烟', '2025-06-20 14:30:00.000000', '2025-07-20 14:30:00.000000', 0, 1, 3);
INSERT INTO `accounts_blacklist` VALUES (3, '破坏公共财物（桌椅）', '2025-08-01 09:00:00.000000', '2025-09-01 09:00:00.000000', 0, 1, 4);
INSERT INTO `accounts_blacklist` VALUES (4, '多次在自习室内大声接打电话，经劝阻无效', '2025-11-10 08:00:00.000000', NULL, 1, 1, 5);
INSERT INTO `accounts_blacklist` VALUES (5, '冒用他人身份预约座位', '2025-12-01 16:00:00.000000', NULL, 1, 1, 3);

-- ============================================================
-- 表：accounts_user（用户表）
-- 说明：继承 Django AbstractUser，扩展学号、手机、角色等字段
-- 关键字段：
--   student_id  - 学号（唯一）
--   role        - 角色：student(学生) / admin(管理员)
--   is_banned   - 是否被封禁
-- ============================================================
DROP TABLE IF EXISTS `accounts_user`;
CREATE TABLE `accounts_user`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `password` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '密码（哈希）',
  `last_login` datetime(6) NULL DEFAULT NULL COMMENT '最后登录时间',
  `is_superuser` tinyint(1) NOT NULL COMMENT '是否超级管理员',
  `username` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户名',
  `first_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `last_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `is_staff` tinyint(1) NOT NULL COMMENT '是否可访问管理后台',
  `is_active` tinyint(1) NOT NULL COMMENT '账户是否激活',
  `date_joined` datetime(6) NOT NULL COMMENT '注册时间',
  `student_id` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '学号（唯一）',
  `email` varchar(254) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '邮箱',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '电话',
  `avatar` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '头像路径',
  `role` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '角色：student/admin',
  `is_banned` tinyint(1) NOT NULL COMMENT '是否被封禁',
  `created_at` datetime(6) NOT NULL COMMENT '创建时间',
  `updated_at` datetime(6) NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `username`(`username`) USING BTREE,
  UNIQUE INDEX `student_id`(`student_id`) USING BTREE,
  UNIQUE INDEX `email`(`email`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- 示例用户数据（5条）：
--   ID=1: admin123  - 管理员（超级用户，可访问后台）
--   ID=2: aaaa1234  - 学生（学号12345，已上传头像）
--   ID=3: zhangsan  - 学生（学号2021001）
--   ID=4: lisi      - 学生（学号2021002）
--   ID=5: wangwu    - 学生（学号2021003，已被封禁）
INSERT INTO `accounts_user` VALUES (1, 'pbkdf2_sha256$260000$T0xHTZc8cDfW6Ic7Kl4xXD$kLGPMAGzaYLaPNpE1kEfb7RGQ2LAsERPZC07vpXts08=', '2025-12-17 02:22:02.241522', 1, 'admin123', '', '', 1, 1, '2025-12-16 07:47:36.965721', '', 'admin123@qq.com', '', '', 'student', 0, '2025-12-16 07:47:37.029283', '2025-12-16 07:47:37.029283');
INSERT INTO `accounts_user` VALUES (2, 'pbkdf2_sha256$260000$F11pZzXgxH4Ia8OqXkC8Kv$x6Tr6RahMBY/OY/mKawMPD+2iGY+G+ojsHowHPfz4KI=', '2025-12-17 02:25:24.425529', 0, 'aaaa1234', '', '', 0, 1, '2025-12-16 08:00:25.515617', '12345', 'aaa@qq.com', '2322111', 'avatars/格子衫.jpg', 'student', 0, '2025-12-16 08:00:25.799753', '2025-12-16 08:00:49.414181');
INSERT INTO `accounts_user` VALUES (3, 'pbkdf2_sha256$260000$A1b2C3d4E5f6G7h8I9j0K1$abcdefgHIJKLMNOPQRSTUVWXYZ0123456789abcdefghij=', '2025-12-20 09:15:00.000000', 0, 'zhangsan', '', '', 0, 1, '2025-12-20 09:15:00.000000', '2021001', 'zhangsan@qq.com', '13800001001', '', 'student', 0, '2025-12-20 09:15:00.000000', '2025-12-20 09:15:00.000000');
INSERT INTO `accounts_user` VALUES (4, 'pbkdf2_sha256$260000$B2c3D4e5F6g7H8i9J0k1L$bcdefghIJKLMNOPQRSTUVWXYZ0123456789abcdefghijkl=', '2025-12-21 10:30:00.000000', 0, 'lisi', '', '', 0, 1, '2025-12-21 10:30:00.000000', '2021002', 'lisi@qq.com', '13800001002', '', 'student', 0, '2025-12-21 10:30:00.000000', '2025-12-21 10:30:00.000000');
INSERT INTO `accounts_user` VALUES (5, 'pbkdf2_sha256$260000$C3d4E5f6G7h8I9j0K1L2m$cdefghiJKLMNOPQRSTUVWXYZ0123456789abcdefghijklm=', '2025-12-22 14:00:00.000000', 0, 'wangwu', '', '', 0, 1, '2025-12-22 14:00:00.000000', '2021003', 'wangwu@qq.com', '13800001003', '', 'student', 1, '2025-12-22 14:00:00.000000', '2025-12-22 14:00:00.000000');

-- ============================================================
-- 表：accounts_user_groups（用户-组关联表）
-- 说明：Django 权限框架的 ManyToMany 中间表
-- ============================================================
DROP TABLE IF EXISTS `accounts_user_groups`;
CREATE TABLE `accounts_user_groups`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `accounts_user_groups_user_id_group_id_59c0b32f_uniq`(`user_id`, `group_id`) USING BTREE,
  INDEX `accounts_user_groups_group_id_bd11a704_fk_auth_group_id`(`group_id`) USING BTREE,
  CONSTRAINT `accounts_user_groups_group_id_bd11a704_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `accounts_user_groups_user_id_52b62117_fk_accounts_user_id` FOREIGN KEY (`user_id`) REFERENCES `accounts_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- （暂无记录）

-- ============================================================
-- 表：accounts_user_user_permissions（用户-权限关联表）
-- 说明：Django 权限框架的 ManyToMany 中间表
-- ============================================================
DROP TABLE IF EXISTS `accounts_user_user_permissions`;
CREATE TABLE `accounts_user_user_permissions`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `accounts_user_user_permi_user_id_permission_id_2ab516c2_uniq`(`user_id`, `permission_id`) USING BTREE,
  INDEX `accounts_user_user_p_permission_id_113bb443_fk_auth_perm`(`permission_id`) USING BTREE,
  CONSTRAINT `accounts_user_user_p_permission_id_113bb443_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `accounts_user_user_p_user_id_e4f0a161_fk_accounts_` FOREIGN KEY (`user_id`) REFERENCES `accounts_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- （暂无记录）

-- ============================================================
-- 表：auth_group（Django 权限组）
-- ============================================================
DROP TABLE IF EXISTS `auth_group`;
CREATE TABLE `auth_group`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `name`(`name`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- （暂无记录）

-- ============================================================
-- 表：auth_group_permissions（组-权限关联表）
-- ============================================================
DROP TABLE IF EXISTS `auth_group_permissions`;
CREATE TABLE `auth_group_permissions`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `auth_group_permissions_group_id_permission_id_0cd325b0_uniq`(`group_id`, `permission_id`) USING BTREE,
  INDEX `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm`(`permission_id`) USING BTREE,
  CONSTRAINT `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `auth_group_permissions_group_id_b120cbf9_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- （暂无记录）

-- ============================================================
-- 表：auth_permission（Django 权限表）
-- 说明：存储系统所有模型的操作权限（增/改/删/查）
-- 权限分组：
--   ID 1-4   : admin.logentry      (后台日志)
--   ID 5-8   : auth.permission     (权限管理)
--   ID 9-12  : auth.group           (权限组)
--   ID 13-16 : contenttypes         (内容类型)
--   ID 17-20 : sessions             (会话)
--   ID 21-24 : accounts.user        (用户)
--   ID 25-28 : accounts.blacklist   (黑名单)
--   ID 29-32 : rooms.studyroom      (自习室)
--   ID 33-36 : rooms.seat           (座位)
--   ID 37-40 : bookings.booking     (预约)
-- ============================================================
DROP TABLE IF EXISTS `auth_permission`;
CREATE TABLE `auth_permission`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `content_type_id` int(11) NOT NULL COMMENT '对应的模型类型ID',
  `codename` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '权限代码名',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `auth_permission_content_type_id_codename_01ab375a_uniq`(`content_type_id`, `codename`) USING BTREE,
  CONSTRAINT `auth_permission_content_type_id_2f476e4b_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 45 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

INSERT INTO `auth_permission` VALUES (1, 'Can add log entry', 1, 'add_logentry');
INSERT INTO `auth_permission` VALUES (2, 'Can change log entry', 1, 'change_logentry');
INSERT INTO `auth_permission` VALUES (3, 'Can delete log entry', 1, 'delete_logentry');
INSERT INTO `auth_permission` VALUES (4, 'Can view log entry', 1, 'view_logentry');
INSERT INTO `auth_permission` VALUES (5, 'Can add permission', 2, 'add_permission');
INSERT INTO `auth_permission` VALUES (6, 'Can change permission', 2, 'change_permission');
INSERT INTO `auth_permission` VALUES (7, 'Can delete permission', 2, 'delete_permission');
INSERT INTO `auth_permission` VALUES (8, 'Can view permission', 2, 'view_permission');
INSERT INTO `auth_permission` VALUES (9, 'Can add group', 3, 'add_group');
INSERT INTO `auth_permission` VALUES (10, 'Can change group', 3, 'change_group');
INSERT INTO `auth_permission` VALUES (11, 'Can delete group', 3, 'delete_group');
INSERT INTO `auth_permission` VALUES (12, 'Can view group', 3, 'view_group');
INSERT INTO `auth_permission` VALUES (13, 'Can add content type', 4, 'add_contenttype');
INSERT INTO `auth_permission` VALUES (14, 'Can change content type', 4, 'change_contenttype');
INSERT INTO `auth_permission` VALUES (15, 'Can delete content type', 4, 'delete_contenttype');
INSERT INTO `auth_permission` VALUES (16, 'Can view content type', 4, 'view_contenttype');
INSERT INTO `auth_permission` VALUES (17, 'Can add session', 5, 'add_session');
INSERT INTO `auth_permission` VALUES (18, 'Can change session', 5, 'change_session');
INSERT INTO `auth_permission` VALUES (19, 'Can delete session', 5, 'delete_session');
INSERT INTO `auth_permission` VALUES (20, 'Can view session', 5, 'view_session');
INSERT INTO `auth_permission` VALUES (21, 'Can add 用户', 6, 'add_user');
INSERT INTO `auth_permission` VALUES (22, 'Can change 用户', 6, 'change_user');
INSERT INTO `auth_permission` VALUES (23, 'Can delete 用户', 6, 'delete_user');
INSERT INTO `auth_permission` VALUES (24, 'Can view 用户', 6, 'view_user');
INSERT INTO `auth_permission` VALUES (25, 'Can add 黑名单', 7, 'add_blacklist');
INSERT INTO `auth_permission` VALUES (26, 'Can change 黑名单', 7, 'change_blacklist');
INSERT INTO `auth_permission` VALUES (27, 'Can delete 黑名单', 7, 'delete_blacklist');
INSERT INTO `auth_permission` VALUES (28, 'Can view 黑名单', 7, 'view_blacklist');
INSERT INTO `auth_permission` VALUES (29, 'Can add 自习室', 8, 'add_studyroom');
INSERT INTO `auth_permission` VALUES (30, 'Can change 自习室', 8, 'change_studyroom');
INSERT INTO `auth_permission` VALUES (31, 'Can delete 自习室', 8, 'delete_studyroom');
INSERT INTO `auth_permission` VALUES (32, 'Can view 自习室', 8, 'view_studyroom');
INSERT INTO `auth_permission` VALUES (33, 'Can add 座位', 9, 'add_seat');
INSERT INTO `auth_permission` VALUES (34, 'Can change 座位', 9, 'change_seat');
INSERT INTO `auth_permission` VALUES (35, 'Can delete 座位', 9, 'delete_seat');
INSERT INTO `auth_permission` VALUES (36, 'Can view 座位', 9, 'view_seat');
INSERT INTO `auth_permission` VALUES (37, 'Can add 预约', 10, 'add_booking');
INSERT INTO `auth_permission` VALUES (38, 'Can change 预约', 10, 'change_booking');
INSERT INTO `auth_permission` VALUES (39, 'Can delete 预约', 10, 'delete_booking');
INSERT INTO `auth_permission` VALUES (40, 'Can view 预约', 10, 'view_booking');

-- ===================================================================
-- 第2部分：核心业务表
-- ===================================================================

-- ============================================================
-- 表：bookings_booking（预约表）
-- 说明：存储用户的座位预约记录
-- 状态流转：
--   pending → approved（默认创建即为已通过）
--   approved → cancelled（用户取消）
--   过期判断：booking_date < 今天 → 视为 expired
-- 约束：同一座位 + 同一日期 + 同一时段 只能有一条 approved 记录
-- 关联：
--   user_id → accounts_user.id
--   seat_id → rooms_seat.id
-- ============================================================
DROP TABLE IF EXISTS `bookings_booking`;
CREATE TABLE `bookings_booking`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `booking_date` date NOT NULL COMMENT '预约日期',
  `time_slot` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '时段：morning/afternoon/evening',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '状态：pending/approved/rejected/cancelled/expired',
  `note` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '备注',
  `created_at` datetime(6) NOT NULL COMMENT '创建时间',
  `updated_at` datetime(6) NOT NULL COMMENT '更新时间',
  `seat_id` bigint(20) NOT NULL COMMENT '座位ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `bookings_booking_seat_id_booking_date_time_slot_9efe12e6_uniq`(`seat_id`, `booking_date`, `time_slot`) USING BTREE,
  INDEX `bookings_booking_user_id_834dfc23_fk_accounts_user_id`(`user_id`) USING BTREE,
  CONSTRAINT `bookings_booking_seat_id_764de9cf_fk_rooms_seat_id` FOREIGN KEY (`seat_id`) REFERENCES `rooms_seat` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `bookings_booking_user_id_834dfc23_fk_accounts_user_id` FOREIGN KEY (`user_id`) REFERENCES `accounts_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- 示例预约数据（5条）：
--   分别覆盖不同用户、不同自习室、不同日期和时段
--   包含 approved 和 cancelled 两种状态
INSERT INTO `bookings_booking` VALUES (1, '2025-12-19', 'afternoon', 'approved', '需要靠窗位置', '2025-12-17 02:19:27.753967', '2025-12-17 02:19:27.753967', 2, 2);
INSERT INTO `bookings_booking` VALUES (2, '2025-12-20', 'morning', 'approved', '', '2025-12-18 08:00:00.000000', '2025-12-18 08:00:00.000000', 1, 3);
INSERT INTO `bookings_booking` VALUES (3, '2025-12-20', 'afternoon', 'approved', '备考期末', '2025-12-18 10:00:00.000000', '2025-12-18 10:00:00.000000', 5, 4);
INSERT INTO `bookings_booking` VALUES (4, '2025-12-21', 'evening', 'cancelled', '临时有事取消', '2025-12-19 15:00:00.000000', '2025-12-19 16:00:00.000000', 8, 2);
INSERT INTO `bookings_booking` VALUES (5, '2025-12-22', 'morning', 'approved', '', '2025-12-20 07:30:00.000000', '2025-12-20 07:30:00.000000', 3, 5);

-- ===================================================================
-- 第3部分：Django 框架表
-- ===================================================================

-- ============================================================
-- 表：django_admin_log（管理后台操作日志）
-- ============================================================
DROP TABLE IF EXISTS `django_admin_log`;
CREATE TABLE `django_admin_log`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `action_time` datetime(6) NOT NULL COMMENT '操作时间',
  `object_id` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL COMMENT '操作对象ID',
  `object_repr` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '对象名称',
  `action_flag` smallint(5) UNSIGNED NOT NULL COMMENT '操作类型：1=新增 2=修改 3=删除',
  `change_message` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '变更内容',
  `content_type_id` int(11) NULL DEFAULT NULL COMMENT '模型类型ID',
  `user_id` bigint(20) NOT NULL COMMENT '操作用户ID',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `django_admin_log_content_type_id_c4bce8eb_fk_django_co`(`content_type_id`) USING BTREE,
  INDEX `django_admin_log_user_id_c564eba6_fk_accounts_user_id`(`user_id`) USING BTREE,
  CONSTRAINT `django_admin_log_content_type_id_c4bce8eb_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `django_admin_log_user_id_c564eba6_fk_accounts_user_id` FOREIGN KEY (`user_id`) REFERENCES `accounts_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- 管理后台操作日志（5条）：
--   action_flag: 1=新增 2=修改 3=删除
INSERT INTO `django_admin_log` VALUES (1, '2025-12-17 02:22:33.812808', '5', '五号自习室', 2, '[{\"changed\": {\"fields\": [\"\\u72b6\\u6001\"]}}]', 8, 1);
INSERT INTO `django_admin_log` VALUES (2, '2025-12-18 09:00:00.000000', '6', '六号自习室', 1, '[{\"added\": {}}]', 8, 1);
INSERT INTO `django_admin_log` VALUES (3, '2025-12-19 10:00:00.000000', '3', 'zhangsan', 2, '[{\"changed\": {\"fields\": [\"phone\"]}}]', 6, 1);
INSERT INTO `django_admin_log` VALUES (4, '2025-12-20 14:00:00.000000', '4', '违规封禁原因', 1, '[{\"added\": {\"name\": \"blacklist\"}}]', 7, 1);
INSERT INTO `django_admin_log` VALUES (5, '2025-12-21 16:00:00.000000', '2', 'aaaa1234', 2, '[{\"changed\": {\"fields\": [\"is_banned\"]}}]', 6, 1);

-- ============================================================
-- 表：django_content_type（Django 模型类型注册表）
-- 说明：记录项目中所有已注册的模型，供权限框架使用
-- ============================================================
DROP TABLE IF EXISTS `django_content_type`;
CREATE TABLE `django_content_type`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_label` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '应用名',
  `model` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '模型名',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `django_content_type_app_label_model_76bd3d3b_uniq`(`app_label`, `model`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

INSERT INTO `django_content_type` VALUES (7, 'accounts', 'blacklist');
INSERT INTO `django_content_type` VALUES (6, 'accounts', 'user');
INSERT INTO `django_content_type` VALUES (1, 'admin', 'logentry');
INSERT INTO `django_content_type` VALUES (3, 'auth', 'group');
INSERT INTO `django_content_type` VALUES (2, 'auth', 'permission');
INSERT INTO `django_content_type` VALUES (10, 'bookings', 'booking');
INSERT INTO `django_content_type` VALUES (4, 'contenttypes', 'contenttype');
INSERT INTO `django_content_type` VALUES (9, 'rooms', 'seat');
INSERT INTO `django_content_type` VALUES (8, 'rooms', 'studyroom');
INSERT INTO `django_content_type` VALUES (5, 'sessions', 'session');

-- ============================================================
-- 表：django_migrations（Django 迁移记录）
-- 说明：记录已执行的数据库迁移，Django 据此判断哪些迁移需要执行
-- ============================================================
DROP TABLE IF EXISTS `django_migrations`;
CREATE TABLE `django_migrations`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `app` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '应用名',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '迁移文件名',
  `applied` datetime(6) NOT NULL COMMENT '执行时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 22 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

INSERT INTO `django_migrations` VALUES (1, 'contenttypes', '0001_initial', '2025-12-16 07:46:54.066116');
INSERT INTO `django_migrations` VALUES (2, 'contenttypes', '0002_remove_content_type_name', '2025-12-16 07:46:54.137194');
INSERT INTO `django_migrations` VALUES (3, 'auth', '0001_initial', '2025-12-16 07:46:54.444877');
INSERT INTO `django_migrations` VALUES (4, 'auth', '0002_alter_permission_name_max_length', '2025-12-16 07:46:54.496808');
INSERT INTO `django_migrations` VALUES (5, 'auth', '0003_alter_user_email_max_length', '2025-12-16 07:46:54.503232');
INSERT INTO `django_migrations` VALUES (6, 'auth', '0004_alter_user_username_opts', '2025-12-16 07:46:54.514938');
INSERT INTO `django_migrations` VALUES (7, 'auth', '0005_alter_user_last_login_null', '2025-12-16 07:46:54.523835');
INSERT INTO `django_migrations` VALUES (8, 'auth', '0006_require_contenttypes_0002', '2025-12-16 07:46:54.529534');
INSERT INTO `django_migrations` VALUES (9, 'auth', '0007_alter_validators_add_error_messages', '2025-12-16 07:46:54.535920');
INSERT INTO `django_migrations` VALUES (10, 'auth', '0008_alter_user_username_max_length', '2025-12-16 07:46:54.544965');
INSERT INTO `django_migrations` VALUES (11, 'auth', '0009_alter_user_last_name_max_length', '2025-12-16 07:46:54.553131');
INSERT INTO `django_migrations` VALUES (12, 'auth', '0010_alter_group_name_max_length', '2025-12-16 07:46:54.573247');
INSERT INTO `django_migrations` VALUES (13, 'auth', '0011_update_proxy_permissions', '2025-12-16 07:46:54.581856');
INSERT INTO `django_migrations` VALUES (14, 'auth', '0012_alter_user_first_name_max_length', '2025-12-16 07:46:54.592056');
INSERT INTO `django_migrations` VALUES (15, 'accounts', '0001_initial', '2025-12-16 07:46:55.243678');
INSERT INTO `django_migrations` VALUES (16, 'admin', '0001_initial', '2025-12-16 07:46:55.426795');
INSERT INTO `django_migrations` VALUES (17, 'admin', '0002_logentry_remove_auto_add', '2025-12-16 07:46:55.434019');
INSERT INTO `django_migrations` VALUES (18, 'admin', '0003_logentry_add_action_flag_choices', '2025-12-16 07:46:55.443071');
INSERT INTO `django_migrations` VALUES (19, 'rooms', '0001_initial', '2025-12-16 07:46:55.733874');
INSERT INTO `django_migrations` VALUES (20, 'bookings', '0001_initial', '2025-12-16 07:46:55.997613');
INSERT INTO `django_migrations` VALUES (21, 'sessions', '0001_initial', '2025-12-16 07:46:56.066589');

-- ============================================================
-- 表：django_session（Django 会话表）
-- 说明：存储用户登录会话数据
-- ============================================================
DROP TABLE IF EXISTS `django_session`;
CREATE TABLE `django_session`  (
  `session_key` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '会话密钥',
  `session_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '加密的会话数据',
  `expire_date` datetime(6) NOT NULL COMMENT '过期时间',
  PRIMARY KEY (`session_key`) USING BTREE,
  INDEX `django_session_expire_date_a5c62663`(`expire_date`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- （会话数据运行时动态生成）

-- ===================================================================
-- 第4部分：自习室与座位表
-- ===================================================================

-- ============================================================
-- 表：rooms_seat（座位表）
-- 说明：每个座位属于一个自习室，用行号+列号定位
-- 状态：
--   available  - 可预约（物理可用）
--   occupied   - 已占用（今天有 approved 预约）
--   unavailable - 不可用（设备故障等）
-- 约束：同一自习室内座位号唯一
-- 关联：room_id → rooms_studyroom.id
-- ============================================================
DROP TABLE IF EXISTS `rooms_seat`;
CREATE TABLE `rooms_seat`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `seat_number` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '座位号（如 A1, B2）',
  `row` int(11) NOT NULL COMMENT '行号',
  `column` int(11) NOT NULL COMMENT '列号',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '状态：available/occupied/unavailable',
  `has_power` tinyint(1) NOT NULL COMMENT '是否有电源插座',
  `has_lamp` tinyint(1) NOT NULL COMMENT '是否有台灯',
  `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '描述',
  `created_at` datetime(6) NOT NULL COMMENT '创建时间',
  `updated_at` datetime(6) NOT NULL COMMENT '更新时间',
  `room_id` bigint(20) NOT NULL COMMENT '所属自习室ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `rooms_seat_room_id_seat_number_ddc31ca3_uniq`(`room_id`, `seat_number`) USING BTREE,
  CONSTRAINT `rooms_seat_room_id_7d24ad15_fk_rooms_studyroom_id` FOREIGN KEY (`room_id`) REFERENCES `rooms_studyroom` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 25 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- 座位数据：共 7 间自习室，24 个座位
-- 编号规则：行号(1,2...) × 列号(1,2...) → 座位号(A1, A2, B1, B2...)

-- 一号自习室（ID=1）：4 个座位，2×2 布局
INSERT INTO `rooms_seat` VALUES (1, 'A1', 1, 1, 'available', 1, 0, '', '2024-06-01 09:10:00.000000', '2024-06-01 09:10:00.000000', 1);
INSERT INTO `rooms_seat` VALUES (2, 'A2', 1, 2, 'available', 1, 1, '', '2024-06-01 09:10:00.000000', '2024-06-01 09:10:00.000000', 1);
INSERT INTO `rooms_seat` VALUES (3, 'B1', 2, 1, 'occupied', 1, 0, '', '2024-06-01 09:10:00.000000', '2024-06-01 09:10:00.000000', 1);
INSERT INTO `rooms_seat` VALUES (4, 'B2', 2, 2, 'available', 0, 0, '', '2024-06-01 09:10:00.000000', '2024-06-01 09:10:00.000000', 1);

-- 二号自习室（ID=2）：4 个座位，2×2 布局
INSERT INTO `rooms_seat` VALUES (5, 'A1', 1, 1, 'available', 1, 0, '', '2024-06-01 09:11:00.000000', '2024-06-01 09:11:00.000000', 2);
INSERT INTO `rooms_seat` VALUES (6, 'A2', 1, 2, 'unavailable', 1, 1, '', '2024-06-01 09:11:00.000000', '2024-06-01 09:11:00.000000', 2);
INSERT INTO `rooms_seat` VALUES (7, 'B1', 2, 1, 'occupied', 1, 0, '', '2024-06-01 09:11:00.000000', '2024-06-01 09:11:00.000000', 2);
INSERT INTO `rooms_seat` VALUES (8, 'B2', 2, 2, 'available', 0, 0, '', '2024-06-01 09:11:00.000000', '2024-06-01 09:11:00.000000', 2);

-- 三号自习室（ID=3）：4 个座位，2×2 布局
INSERT INTO `rooms_seat` VALUES (9, 'C1', 1, 1, 'available', 1, 1, '', '2024-06-01 09:12:00.000000', '2024-06-01 09:12:00.000000', 3);
INSERT INTO `rooms_seat` VALUES (10, 'C2', 1, 2, 'occupied', 0, 1, '', '2024-06-01 09:12:00.000000', '2024-06-01 09:12:00.000000', 3);
INSERT INTO `rooms_seat` VALUES (11, 'D1', 2, 1, 'available', 1, 0, '', '2024-06-01 09:12:00.000000', '2024-06-01 09:12:00.000000', 3);
INSERT INTO `rooms_seat` VALUES (12, 'D2', 2, 2, 'available', 1, 0, '', '2024-06-01 09:12:00.000000', '2024-06-01 09:12:00.000000', 3);

-- 四号自习室（ID=4）：4 个座位，2×2 布局
INSERT INTO `rooms_seat` VALUES (13, 'E1', 1, 1, 'unavailable', 0, 1, '', '2024-06-01 09:13:00.000000', '2024-06-01 09:13:00.000000', 4);
INSERT INTO `rooms_seat` VALUES (14, 'E2', 1, 2, 'available', 1, 0, '', '2024-06-01 09:13:00.000000', '2024-06-01 09:13:00.000000', 4);
INSERT INTO `rooms_seat` VALUES (15, 'F1', 2, 1, 'occupied', 0, 0, '', '2024-06-01 09:13:00.000000', '2024-06-01 09:13:00.000000', 4);
INSERT INTO `rooms_seat` VALUES (16, 'F2', 2, 2, 'occupied', 1, 1, '', '2024-06-01 09:13:00.000000', '2024-06-01 09:13:00.000000', 4);

-- 五号自习室（ID=5）：4 个座位，2×2 布局
INSERT INTO `rooms_seat` VALUES (17, 'G1', 1, 1, 'occupied', 1, 0, '', '2024-06-01 09:14:00.000000', '2024-06-01 09:14:00.000000', 5);
INSERT INTO `rooms_seat` VALUES (18, 'G2', 1, 2, 'unavailable', 0, 1, '', '2024-06-01 09:14:00.000000', '2024-06-01 09:14:00.000000', 5);
INSERT INTO `rooms_seat` VALUES (19, 'H1', 2, 1, 'unavailable', 0, 0, '', '2024-06-01 09:14:00.000000', '2024-06-01 09:14:00.000000', 5);
INSERT INTO `rooms_seat` VALUES (20, 'H2', 2, 2, 'unavailable', 1, 1, '', '2024-06-01 09:14:00.000000', '2024-06-01 09:14:00.000000', 5);

-- 六号自习室（ID=6）：2 个座位（当前 1×2，后续可扩展至 6 个）
INSERT INTO `rooms_seat` VALUES (21, 'A1', 1, 1, 'available', 1, 0, '窗边座位', '2024-06-02 08:00:00.000000', '2024-06-02 08:00:00.000000', 6);
INSERT INTO `rooms_seat` VALUES (22, 'A2', 1, 2, 'available', 1, 1, '靠门有台灯', '2024-06-02 08:00:00.000000', '2024-06-02 08:00:00.000000', 6);

-- 七号自习室（ID=7）：2 个座位（当前 1×2，后续可扩展至 8 个）
INSERT INTO `rooms_seat` VALUES (23, 'B1', 1, 1, 'available', 1, 1, '夜灯座', '2024-06-02 08:15:00.000000', '2024-06-02 08:15:00.000000', 7);
INSERT INTO `rooms_seat` VALUES (24, 'B2', 1, 2, 'available', 0, 1, '靠窗台灯位', '2024-06-02 08:15:00.000000', '2024-06-02 08:15:00.000000', 7);

-- ============================================================
-- 表：rooms_studyroom（自习室表）
-- 说明：存储自习室基本信息
-- 状态：
--   open        - 开放中（可预约）
--   closed      - 已关闭
--   maintenance - 维护中
-- 关键字段：
--   total_seats    - 总座位数（由座位表统计）
--   available_seats - 可用座位数（由系统自动维护，基于座位状态计数）
--   open_time/close_time - 开放时间
--   facilities - 设备设施描述
-- ============================================================
DROP TABLE IF EXISTS `rooms_studyroom`;
CREATE TABLE `rooms_studyroom`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '自习室名称',
  `location` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '位置描述',
  `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '描述',
  `image` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '图片路径',
  `total_seats` int(11) NOT NULL COMMENT '总座位数',
  `available_seats` int(11) NOT NULL COMMENT '当前可用座位数',
  `open_time` time(6) NOT NULL COMMENT '开放时间',
  `close_time` time(6) NOT NULL COMMENT '关闭时间',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '状态：open/closed/maintenance',
  `facilities` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '设备设施',
  `created_at` datetime(6) NOT NULL COMMENT '创建时间',
  `updated_at` datetime(6) NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- 自习室数据：共 7 间，统一开放时间 08:00-22:00
INSERT INTO `rooms_studyroom` VALUES (1, '一号自习室', '教学楼A101', '宽敞明亮', NULL, 4, 4, '08:00:00.000000', '22:00:00.000000', 'open', '空调, 插座, WiFi', '2024-06-01 09:00:00.000000', '2024-06-01 09:00:00.000000');
INSERT INTO `rooms_studyroom` VALUES (2, '二号自习室', '教学楼B201', '安静舒适', NULL, 4, 3, '08:00:00.000000', '22:00:00.000000', 'open', '空调, 插座', '2024-06-01 09:01:00.000000', '2024-06-01 09:01:00.000000');
INSERT INTO `rooms_studyroom` VALUES (3, '三号自习室', '图书馆301', '靠窗环境', NULL, 4, 4, '08:00:00.000000', '22:00:00.000000', 'maintenance', 'WiFi, 插座', '2024-06-01 09:02:00.000000', '2024-06-01 09:02:00.000000');
INSERT INTO `rooms_studyroom` VALUES (4, '四号自习室', '宿舍楼活动室', '小型自习室', NULL, 4, 2, '08:00:00.000000', '22:00:00.000000', 'open', '空调', '2024-06-01 09:03:00.000000', '2024-06-01 09:03:00.000000');
INSERT INTO `rooms_studyroom` VALUES (5, '五号自习室', '教学楼C401', '考试周开放', '', 4, 0, '08:00:00.000000', '22:00:00.000000', 'open', '插座', '2024-06-01 09:04:00.000000', '2025-12-17 02:22:33.809069');
INSERT INTO `rooms_studyroom` VALUES (6, '六号自习室', '科技楼5F', '环境优雅，适合小组讨论', NULL, 6, 5, '08:00:00.000000', '22:00:00.000000', 'open', '空调, 插座, 黑板, WiFi', '2024-06-02 08:00:00.000000', '2024-06-02 08:00:00.000000');
INSERT INTO `rooms_studyroom` VALUES (7, '七号自习室', '教学楼D203', '夜间开放，灯光充足', NULL, 8, 7, '08:00:00.000000', '22:00:00.000000', 'open', '插座, WiFi, 空调, 台灯', '2024-06-02 08:15:00.000000', '2024-06-02 08:15:00.000000');

-- ===================================================================
-- 第5部分：视图（Views）
-- 说明：视图用于简化复杂的跨表查询，提供统一的数据接口。
--       视图本身不存储数据，每次查询时动态生成结果。
-- ===================================================================

-- ============================================================
-- 视图1：v_user_booking_record（用户预约记录视图）
-- 说明：关联用户、预约、座位、自习室四张表，方便管理员
--       或前端一次性查看完整的预约信息，无需多次 JOIN。
-- 字段：user_id, username, student_id, booking_id, booking_date,
--       time_slot, booking_status, seat_number, seat_id, room_name, location
-- ============================================================
DROP VIEW IF EXISTS `v_user_booking_record`;
CREATE VIEW `v_user_booking_record` AS
SELECT
    u.id            AS user_id,
    u.username      AS username,
    u.student_id    AS student_id,
    b.id            AS booking_id,
    b.booking_date  AS booking_date,
    b.time_slot     AS time_slot,
    b.status        AS booking_status,
    s.seat_number   AS seat_number,
    s.id            AS seat_id,
    r.name          AS room_name,
    r.location      AS location
FROM accounts_user u
JOIN bookings_booking b ON u.id = b.user_id
JOIN rooms_seat s       ON b.seat_id = s.id
JOIN rooms_studyroom r  ON s.room_id = r.id
ORDER BY b.booking_date DESC, b.time_slot;

-- 调用示例：SELECT * FROM v_user_booking_record WHERE student_id = '2021001';

-- ============================================================
-- 视图2：v_room_available_stat（自习室可用统计视图）
-- 说明：统计每间自习室的座位使用情况，包括实际可用数、
--       已占用数、不可用数和占用率，方便首页实时展示。
-- 字段：room_id, room_name, total_seats, actual_available,
--       actual_occupied, actual_unavailable, occupancy_rate
-- ============================================================
DROP VIEW IF EXISTS `v_room_available_stat`;
CREATE VIEW `v_room_available_stat` AS
SELECT
    r.id                AS room_id,
    r.name              AS room_name,
    r.total_seats       AS total_seats,
    COUNT(s.id)         AS actual_seat_count,
    SUM(CASE WHEN s.status = 'available'   THEN 1 ELSE 0 END) AS actual_available,
    SUM(CASE WHEN s.status = 'occupied'    THEN 1 ELSE 0 END) AS actual_occupied,
    SUM(CASE WHEN s.status = 'unavailable' THEN 1 ELSE 0 END) AS actual_unavailable,
    CONCAT(ROUND(
        SUM(CASE WHEN s.status = 'available' THEN 1 ELSE 0 END)
        / COUNT(s.id) * 100, 2
    ), '%')             AS occupancy_rate
FROM rooms_studyroom r
LEFT JOIN rooms_seat s ON r.id = s.room_id
GROUP BY r.id, r.name, r.total_seats
ORDER BY r.name;

-- 调用示例：SELECT * FROM v_room_available_stat WHERE actual_available > 0;

-- ===================================================================
-- 第6部分：存储过程（Stored Procedures）
-- 说明：存储过程封装了常用的数据库操作逻辑，可直接通过
--       CALL 语句调用，减少应用层代码的数据库交互次数。
-- ===================================================================

-- ============================================================
-- 存储过程1：p_get_user_booking_by_student
-- 功能：根据学号查询该用户的所有预约记录
-- 参数：p_student_id VARCHAR(20) - 学生学号
-- 返回：通过 v_user_booking_record 视图返回完整预约信息
-- 示例：CALL p_get_user_booking_by_student('2021001');
-- ============================================================
DROP PROCEDURE IF EXISTS `p_get_user_booking_by_student`;
DELIMITER $$
CREATE PROCEDURE `p_get_user_booking_by_student`(IN p_student_id VARCHAR(20))
BEGIN
    SELECT
        booking_id,
        booking_date,
        time_slot,
        booking_status,
        seat_number,
        room_name,
        location
    FROM v_user_booking_record
    WHERE student_id = p_student_id
    ORDER BY booking_date DESC, time_slot;
END$$
DELIMITER ;

-- ============================================================
-- 存储过程2：p_batch_insert_seat
-- 功能：为指定自习室批量生成座位（行×列网格）
-- 参数：
--   p_room_id   INT - 目标自习室ID
--   p_row_num   INT - 行数（会自动转为字母：1→A, 2→B...）
--   p_col_num   INT - 列数（数字编号：1, 2, 3...）
-- 说明：座位号命名规则为「行字母 + 列数字」，
--       如第1行第2列 → A2；第3行第4列 → C4
--       生成后自动更新对应自习室的 total_seats 字段
-- 示例：CALL p_batch_insert_seat(8, 3, 4);
--       给8号自习室生成 3排×4列 共12个座位
-- ============================================================
DROP PROCEDURE IF EXISTS `p_batch_insert_seat`;
DELIMITER $$
CREATE PROCEDURE `p_batch_insert_seat`(
    IN p_room_id INT,
    IN p_row_num INT,
    IN p_col_num INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE j INT DEFAULT 1;
    DECLARE seat_label CHAR(10);

    -- 外层循环：遍历每一行（对应字母 A, B, C...）
    WHILE i <= p_row_num DO
        SET j = 1;
        -- 内层循环：遍历每一列（对应数字 1, 2, 3...）
        WHILE j <= p_col_num DO
            -- 拼接座位号：CHR(64+i) 将 1→A, 2→B, 3→C...
            SET seat_label = CONCAT(CHAR(64 + i), j);
            INSERT INTO rooms_seat
                (seat_number, `row`, `column`, status, has_power, has_lamp,
                 description, created_at, updated_at, room_id)
            VALUES
                (seat_label, i, j, 'available', 1, 0, '', NOW(), NOW(), p_room_id);
            SET j = j + 1;
        END WHILE;
        SET i = i + 1;
    END WHILE;

    -- 更新自习室的总座位数
    UPDATE rooms_studyroom
    SET total_seats = (SELECT COUNT(*) FROM rooms_seat WHERE room_id = p_room_id)
    WHERE id = p_room_id;
END$$
DELIMITER ;

-- ===================================================================
-- 第7部分：触发器（Triggers）
-- 说明：触发器在特定的表操作（INSERT/UPDATE/DELETE）发生时
--       自动执行，无需应用层手动调用，保证数据一致性。
-- ===================================================================

-- ============================================================
-- 触发器1：tr_after_booking_insert（预约新增后触发）
-- 时机：AFTER INSERT ON bookings_booking
-- 功能：新预约创建成功后，自动将对应自习室的
--       available_seats 减 1，保持计数同步。
-- 关联：通过 seat_id → rooms_seat → room_id 找到目标自习室
-- ============================================================
DROP TRIGGER IF EXISTS `tr_after_booking_insert`;
DELIMITER $$
CREATE TRIGGER `tr_after_booking_insert`
AFTER INSERT ON bookings_booking
FOR EACH ROW
BEGIN
    -- 将预约座位所属自习室的可用座位数 -1
    UPDATE rooms_studyroom rs
    JOIN rooms_seat s ON rs.id = s.room_id
    SET rs.available_seats = rs.available_seats - 1
    WHERE s.id = NEW.seat_id;
END$$
DELIMITER ;

-- ============================================================
-- 触发器2：tr_after_booking_update（预约状态变更后触发）
-- 时机：AFTER UPDATE ON bookings_booking
-- 功能：当预约状态变为 cancelled（取消）时，自动将
--       对应自习室的 available_seats 加 1，恢复可用计数。
-- 注：仅处理 cancelled 状态；approved→cancelled 时触发
-- ============================================================
DROP TRIGGER IF EXISTS `tr_after_booking_update`;
DELIMITER $$
CREATE TRIGGER `tr_after_booking_update`
AFTER UPDATE ON bookings_booking
FOR EACH ROW
BEGIN
    -- 仅当状态从非取消变为取消时，恢复可用座位数
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        UPDATE rooms_studyroom rs
        JOIN rooms_seat s ON rs.id = s.room_id
        SET rs.available_seats = rs.available_seats + 1
        WHERE s.id = NEW.seat_id;
    END IF;
END$$
DELIMITER ;

-- ===================================================================
-- 初始化完成
-- ===================================================================
SET FOREIGN_KEY_CHECKS = 1;
