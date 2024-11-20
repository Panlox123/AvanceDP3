-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 20-11-2024 a las 07:06:15
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `prueba1`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddUser` (IN `p_nick_user` VARCHAR(100), IN `p_pass_user` VARCHAR(255), IN `p_email_user` VARCHAR(100), IN `p_tip_user` VARCHAR(50), IN `p_name_person` VARCHAR(100), IN `p_doc_person` INT, IN `p_dir_company` VARCHAR(255), IN `p_cell_company` VARCHAR(20), IN `p_desc_company` VARCHAR(255), IN `p_key_admin` VARCHAR(255))   BEGIN
    DECLARE id_user VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- Llamar al procedimiento para generar el id_user
    CALL GenerateUserId(p_tip_user, p_nick_user, p_email_user , id_user);

    -- Insertar en la tabla de usuarios
    INSERT INTO user (id_user, nick_user, pass_user, email_user, tip_user)
    VALUES (id_user, p_nick_user, p_pass_user, p_email_user, p_tip_user);

    -- Comprobar el tipo de usuario e insertar en la tabla correspondiente
    IF p_tip_user = 'person' THEN
        INSERT INTO userPerson (id_user, name_person, doc_person)
        VALUES (id_user, p_name_person, p_doc_person);
    ELSEIF p_tip_user = 'company' THEN
        INSERT INTO userCompany (id_user, dir_company, cell_company, desc_company)
        VALUES (id_user, p_dir_company, p_cell_company, p_desc_company);
    ELSEIF p_tip_user = 'admin' THEN
        INSERT INTO userAdmin (id_user, key_admin)
        VALUES (id_user, p_key_admin);
    END IF;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuscarCampania` (IN `p_id_campania` VARCHAR(255))   BEGIN
    SELECT * FROM campania WHERE id_campania = p_id_campania;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuscarDonacion` (IN `p_id_donacion` VARCHAR(255))   BEGIN
    SELECT * FROM donaciones WHERE id_donacion = p_id_donacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CrearCampania` (IN `p_id_campania` VARCHAR(255), IN `p_descripcion` VARCHAR(255), IN `p_id_user` VARCHAR(255), IN `p_tipo_campania` VARCHAR(50), IN `p_monto_aporte` DECIMAL(10,2), IN `p_estado_campania` ENUM('Activa','Finalizada','Cancelada'), IN `p_meta_aporte` DECIMAL(10,2), IN `p_fecha_inicio` DATETIME, IN `p_fecha_fin` DATETIME)   BEGIN
    INSERT INTO campania (
        id_campania,
        descripcion,
        id_user,
        tipo_campania,
        monto_aporte,
        estado_campania,
        meta_aporte,
        fecha_inicio,
        fecha_fin
    ) VALUES (
        p_id_campania,
        p_descripcion,
        p_id_user,
        p_tipo_campania,
        p_monto_aporte,
        p_estado_campania,
        p_meta_aporte,
        p_fecha_inicio,
        p_fecha_fin
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `crear_donacion` (IN `p_id_donacion` VARCHAR(255), IN `p_id_campania` VARCHAR(255), IN `p_id_user` VARCHAR(255), IN `p_tipo_donacion` ENUM('dinero','ropa','consumible'), IN `p_cantidad_donacion` DECIMAL(10,2), IN `p_fecha_donacion` DATETIME, IN `p_estado_donacion` ENUM('registrado','finalizado','cancelado'))   BEGIN
    -- Si el estado de donación es NULL, se establece 'registrado' como valor por defecto
    IF p_estado_donacion IS NULL THEN
        SET p_estado_donacion = 'registrado';
    END IF;

    -- Insertar la nueva donación
    INSERT INTO `donaciones` (
        `id_donacion`, 
        `id_campania`, 
        `id_user`, 
        `tipo_donacion`, 
        `cantidad_donacion`, 
        `fecha_donacion`, 
        `estado_donacion`
    ) VALUES (
        p_id_donacion, 
        p_id_campania, 
        p_id_user, 
        p_tipo_donacion, 
        p_cantidad_donacion, 
        p_fecha_donacion, 
        p_estado_donacion
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteUser` (IN `p_id_user` VARCHAR(255))   BEGIN
    DECLARE user_type VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- Obtener el tipo de usuario antes de eliminar
    SELECT `tip_user` INTO user_type FROM `user` WHERE `id_user` = p_id_user;

    -- Verificar el tipo de usuario y eliminar solo en la subtabla correspondiente
    IF user_type = 'person' THEN
        DELETE FROM `userperson` WHERE `id_user` = p_id_user;
    ELSEIF user_type = 'company' THEN
        DELETE FROM `usercompany` WHERE `id_user` = p_id_user;
    ELSEIF user_type = 'admin' THEN
        DELETE FROM `useradmin` WHERE `id_user` = p_id_user;
    END IF;

    -- Eliminar el registro principal de la tabla `user`
    DELETE FROM `user` WHERE `id_user` = p_id_user;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EditarCampania` (IN `p_id_campania` VARCHAR(255), IN `p_descripcion` VARCHAR(255), IN `p_id_user` VARCHAR(255), IN `p_tipo_campania` VARCHAR(50), IN `p_monto_aporte` DECIMAL(10,2), IN `p_estado_campania` ENUM('Activa''Finalizada','Cancelada'), IN `p_meta_aporte` DECIMAL(10,2), IN `p_fecha_inicio` DATETIME, IN `p_fecha_fin` DATETIME)   BEGIN
    UPDATE campania
    SET
        descripcion = IFNULL(NULLIF(p_descripcion, ''), descripcion),  -- Si está vacío, no actualizar
        id_user = IFNULL(NULLIF(p_id_user, ''), id_user),     -- Lo mismo para id_usuario
        tipo_campania = IFNULL(NULLIF(p_tipo_campania, ''), tipo_campania),
        monto_aporte = IFNULL(NULLIF(p_monto_aporte, 0), monto_aporte),  -- No actualizar si es 0
        estado_campania = IFNULL(NULLIF(p_estado_campania, ''), estado_campania),
        meta_aporte = IFNULL(NULLIF(p_meta_aporte, 0), meta_aporte),
        fecha_inicio = IFNULL(NULLIF(p_fecha_inicio, ''), fecha_inicio),
        fecha_fin = IFNULL(NULLIF(p_fecha_fin, ''), fecha_fin)
    WHERE id_campania = p_id_campania;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `editar_donacion` (IN `p_id_donacion` VARCHAR(255), IN `p_id_campania` VARCHAR(255), IN `p_id_user` VARCHAR(255), IN `p_tipo_donacion` ENUM('dinero','ropa','consumible'), IN `p_cantidad_donacion` DECIMAL(10,2), IN `p_fecha_donacion` DATETIME, IN `p_estado_donacion` ENUM('registrado','finalizado','cancelado'))   BEGIN
    -- Actualizar los detalles de la donación solo si el valor no es NULL
    UPDATE `donaciones`
    SET 
        `id_campania` = IFNULL(p_id_campania, `id_campania`),
        `id_user` = IFNULL(p_id_user, `id_user`),
        `tipo_donacion` = IFNULL(p_tipo_donacion, `tipo_donacion`),
        `cantidad_donacion` = IFNULL(p_cantidad_donacion, `cantidad_donacion`),
        `fecha_donacion` = IFNULL(p_fecha_donacion, `fecha_donacion`),
        `estado_donacion` = IFNULL(p_estado_donacion, `estado_donacion`)
    WHERE `id_donacion` = p_id_donacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EliminarCampania` (IN `p_id_campania` VARCHAR(255))   BEGIN
    DELETE FROM campania WHERE id_campania = p_id_campania;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EliminarDonacion` (IN `p_id_donacion` VARCHAR(255))   BEGIN
    DELETE FROM donaciones WHERE id_donacion = p_id_donacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `FindUserById` (IN `p_id_user` VARCHAR(255))   BEGIN
    DECLARE tip_user VARCHAR(50);

    -- Obtener el tipo de usuario
    SELECT u.tip_user INTO tip_user
    FROM user u
    WHERE u.id_user = p_id_user;

    -- Dependiendo del tipo de usuario, se obtienen datos solo de la tabla correspondiente
    IF tip_user = 'person' THEN
        SELECT 
            u.id_user,
            u.nick_user,
            u.pass_user,
            u.email_user,
            up.name_person,
            up.doc_person,
            u.tip_user  -- Asegúrate de seleccionar tip_user
        FROM user u
        JOIN userPerson up ON u.id_user = up.id_user
        WHERE u.id_user = p_id_user;

    ELSEIF tip_user = 'company' THEN
        SELECT 
            u.id_user,
            u.nick_user,
            u.pass_user,
            u.email_user,
            uc.dir_company,
            uc.cell_company,
            uc.desc_company,
            u.tip_user  -- Asegúrate de seleccionar tip_user
        FROM user u
        JOIN userCompany uc ON u.id_user = uc.id_user
        WHERE u.id_user = p_id_user;

    ELSEIF tip_user = 'admin' THEN
        SELECT 
            u.id_user,
            u.nick_user,
            u.pass_user,
            u.email_user,
            ua.key_admin,
            u.tip_user  -- Asegúrate de seleccionar tip_user
        FROM user u
        JOIN userAdmin ua ON u.id_user = ua.id_user
        WHERE u.id_user = p_id_user;

    ELSE
        -- Si el tipo de usuario no coincide con ninguna categoría
        SELECT 'Tipo de usuario no válido o usuario no encontrado' AS mensaje;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GenerateUserId` (IN `p_tip_user` VARCHAR(50), IN `p_nick_user` VARCHAR(100), IN `p_email_user` VARCHAR(100), OUT `p_id_user` VARCHAR(255))   BEGIN
    DECLARE year_suffix VARCHAR(3);
    DECLARE month_digit CHAR(1);
    DECLARE day_digit CHAR(1);
    DECLARE first_letter_nick CHAR(1);
    DECLARE last_letter_nick CHAR(1);
    DECLARE first_letter_email CHAR(1);

    -- Obtener los últimos 3 dígitos del año actual
    SET year_suffix = RIGHT(YEAR(CURDATE()), 3);

    -- Obtener el último dígito del mes
    SET month_digit = RIGHT(MONTH(CURDATE()), 1);

    -- Obtener el último dígito del día
    SET day_digit = RIGHT(DAY(CURDATE()), 1);

    -- Obtener la primera y última letra del nick_user
    SET first_letter_nick = UPPER(LEFT(p_nick_user, 1));
    SET last_letter_nick = UPPER(RIGHT(p_nick_user, 1));

    -- Obtener la primera letra del email_user
    SET first_letter_email = UPPER(LEFT(p_email_user, 1));

    -- Generar el id_user
    SET p_id_user = CONCAT(
        UPPER(LEFT(p_tip_user, 1)),  -- Primera letra del tipo de usuario
        year_suffix,                 -- Últimos 3 dígitos del año
        first_letter_nick,           -- Primera letra del nick
        last_letter_nick,            -- Última letra del nick
        first_letter_email,          -- Primera letra del email
        month_digit,                 -- Último dígito del mes
        day_digit                    -- Último dígito del día
    );

    -- Para depuración
    SELECT p_id_user AS generated_id_user;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListarCampanias` (IN `p_id_user` VARCHAR(255), IN `p_estado_campania` ENUM('Activa','Finalizada','Cancelada'))   BEGIN
    IF (p_id_user IS NULL OR p_id_user = '') AND (p_estado_campania IS NULL OR p_estado_campania = '') THEN
        -- Si no se proporciona ni id_user ni estado, listar todas las campañas
        SELECT * FROM campania;

    ELSEIF (p_id_user IS NOT NULL AND p_id_user <> '') AND (p_estado_campania IS NULL OR p_estado_campania = '') THEN
        -- Si se proporciona solo id_user, listar campañas de ese usuario
        SELECT * FROM campania WHERE id_user = p_id_user;

    ELSEIF (p_id_user IS NULL OR p_id_user = '') AND (p_estado_campania IS NOT NULL AND p_estado_campania <> '') THEN
        -- Si se proporciona solo estado_campania, listar campañas con ese estado
        SELECT * FROM campania WHERE estado_campania = p_estado_campania;

    ELSE
        -- Si se proporcionan ambos, id_user y estado_campania, filtrar por ambos
        SELECT * FROM campania WHERE id_user = p_id_user AND estado_campania = p_estado_campania;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListarDonaciones` (IN `p_id_campania` VARCHAR(255))   BEGIN
    IF p_id_campania IS NULL OR p_id_campania = '' THEN
        -- Si no se proporciona un id_campania, listar todas las donaciones
        SELECT * FROM donaciones;
    ELSE
        -- Si se proporciona un id_campania, filtrar por id_campania
        SELECT * FROM donaciones WHERE id_campania = p_id_campania;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListUsersByType` (IN `p_tip_user` VARCHAR(50))   BEGIN
    IF p_tip_user IS NULL THEN
        -- Listar todos los usuarios
        SELECT 
            u.id_user,
            u.nick_user,
            u.pass_user,
            u.email_user,
            u.tip_user,
            up.name_person,
            up.doc_person,
            uc.dir_company,
            uc.cell_company,
            uc.desc_company,
            ua.key_admin
        FROM user u
        LEFT JOIN userPerson up ON u.id_user = up.id_user
        LEFT JOIN userCompany uc ON u.id_user = uc.id_user
        LEFT JOIN userAdmin ua ON u.id_user = ua.id_user;
    ELSE
        -- Listar usuarios por tipo
        SELECT 
            u.id_user,
            u.nick_user,
            u.pass_user,
            u.email_user,
            u.tip_user,
            up.name_person,
            up.doc_person,
            uc.dir_company,
            uc.cell_company,
            uc.desc_company,
            ua.key_admin
        FROM user u
        LEFT JOIN userPerson up ON u.id_user = up.id_user
        LEFT JOIN userCompany uc ON u.id_user = uc.id_user
        LEFT JOIN userAdmin ua ON u.id_user = ua.id_user
        WHERE u.tip_user = p_tip_user;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `LoginUser` (IN `p_nick_user` VARCHAR(100), IN `p_pass_user` VARCHAR(255))   BEGIN
    DECLARE user_exists INT DEFAULT 0;
    DECLARE user_id VARCHAR(255);

    -- Verificar si el usuario existe y las credenciales son correctas
    SELECT COUNT(*) INTO user_exists
    FROM user
    WHERE nick_user = p_nick_user AND pass_user = p_pass_user;
    
    IF user_exists = 1 THEN
        -- Obtener el id_user del usuario autenticado
        SELECT id_user INTO user_id
        FROM user
        WHERE nick_user = p_nick_user AND pass_user = p_pass_user;
        
        -- Devolver el id_user
        SELECT user_id AS id_user;
    ELSE
        -- Si las credenciales no son correctas
        SELECT 'Usuario o contraseña incorrectos' AS mensaje;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ObtenerCampaniasActivasPorUsuario` (IN `p_id_user` VARCHAR(255), OUT `existe` BOOLEAN)   BEGIN
    -- Verificar si el usuario tiene campañas activas
    IF EXISTS (SELECT 1 FROM campania WHERE id_user = p_id_user AND estado_campania = 'Activa') THEN
        SET existe = TRUE;  -- Existen campañas activas
    ELSE
        SET existe = FALSE; -- No existen campañas activas
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateUser` (IN `p_id_user` VARCHAR(255), IN `p_nick_user` VARCHAR(100), IN `p_pass_user` VARCHAR(255), IN `p_email_user` VARCHAR(100), IN `p_tip_user` VARCHAR(50), IN `p_name_person` VARCHAR(100), IN `p_doc_person` INT, IN `p_dir_company` VARCHAR(255), IN `p_cell_company` VARCHAR(20), IN `p_desc_company` VARCHAR(255), IN `p_key_admin` VARCHAR(255))   BEGIN
    DECLARE tip_user VARCHAR(50);

    -- Obtener el tipo de usuario
    SELECT tip_user INTO tip_user
    FROM user 
    WHERE id_user = p_id_user;

    -- Actualizar en la tabla user
    UPDATE user 
    SET 
        nick_user = IFNULL(p_nick_user, nick_user),
        pass_user = IFNULL(p_pass_user, pass_user),
        email_user = IFNULL(p_email_user, email_user),
        tip_user = IFNULL(p_tip_user, tip_user)
    WHERE id_user = p_id_user;

    -- Dependiendo del tipo de usuario, actualizar en la tabla correspondiente
    IF tip_user = 'person' THEN
        UPDATE userPerson 
        SET 
            name_person = IFNULL(p_name_person, name_person), 
            doc_person = IFNULL(p_doc_person, doc_person) 
        WHERE id_user = p_id_user;

    ELSEIF tip_user = 'company' THEN
        UPDATE userCompany 
        SET 
            dir_company = IFNULL(p_dir_company, dir_company), 
            cell_company = IFNULL(p_cell_company, cell_company), 
            desc_company = IFNULL(p_desc_company, desc_company) 
        WHERE id_user = p_id_user;

    ELSEIF tip_user = 'admin' THEN
        UPDATE userAdmin 
        SET 
            key_admin = IFNULL(p_key_admin, key_admin) 
        WHERE id_user = p_id_user;

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `VerificarCampaniaActiva` (IN `p_id_campania` VARCHAR(255), OUT `p_activa` BOOLEAN)   BEGIN
    DECLARE v_estado ENUM('Activa', 'Finalizada', 'Cancelada');

    -- Obtener el estado de la campaña
    SELECT estado_campania INTO v_estado
    FROM campania
    WHERE id_campania = p_id_campania;

    -- Verificar si el estado es 'Activa'
    IF v_estado = 'Activa' THEN
        SET p_activa = TRUE;
    ELSE
        SET p_activa = FALSE;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `campania`
--

CREATE TABLE `campania` (
  `id_campania` varchar(255) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `id_user` varchar(255) NOT NULL,
  `tipo_campania` varchar(50) NOT NULL,
  `monto_aporte` decimal(10,2) NOT NULL,
  `estado_campania` enum('Activa','Finalizada','Cancelada') DEFAULT 'Activa',
  `meta_aporte` decimal(10,2) DEFAULT NULL,
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `campania`
--

INSERT INTO `campania` (`id_campania`, `descripcion`, `id_user`, `tipo_campania`, `monto_aporte`, `estado_campania`, `meta_aporte`, `fecha_inicio`, `fecha_fin`) VALUES
('afDA1110', 'afavor de daniel', 'A024YOA11', 'Dinero', 5.00, 'Activa', 10000.00, '2024-11-01 00:00:00', '2024-12-01 00:00:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `donaciones`
--

CREATE TABLE `donaciones` (
  `id_donacion` varchar(255) NOT NULL,
  `id_campania` varchar(255) NOT NULL,
  `id_user` varchar(255) NOT NULL,
  `tipo_donacion` enum('dinero','ropa','consumible') NOT NULL,
  `cantidad_donacion` decimal(10,2) NOT NULL,
  `fecha_donacion` datetime NOT NULL,
  `estado_donacion` enum('registrado','finalizado','cancelado') NOT NULL DEFAULT 'registrado'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `donaciones`
--

INSERT INTO `donaciones` (`id_donacion`, `id_campania`, `id_user`, `tipo_donacion`, `cantidad_donacion`, `fecha_donacion`, `estado_donacion`) VALUES
('1', 'afDA1110', 'A024YOA11', 'dinero', 1000.00, '2024-11-13 00:00:00', 'registrado');

--
-- Disparadores `donaciones`
--
DELIMITER $$
CREATE TRIGGER `after_donacion_insert` AFTER INSERT ON `donaciones` FOR EACH ROW BEGIN
    -- Insertar una nueva solicitud con el id_solicitud que es el id_donacion precedido por 'S'
    INSERT INTO solicitudes (id_solicitud, id_donacion, fecha_solicitud, estado_solicitud)
    VALUES (CONCAT('S', NEW.id_donacion), NEW.id_donacion, NOW(), 'PENDIENTE');
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `solicitudes`
--

CREATE TABLE `solicitudes` (
  `id_solicitud` varchar(255) NOT NULL,
  `id_donacion` varchar(255) DEFAULT NULL,
  `fecha_solicitud` datetime NOT NULL,
  `comentarios` text DEFAULT NULL,
  `estado_solicitud` enum('PENDIENTE','VERIFICADA','PROCESADA','FINALIZADA') DEFAULT 'PENDIENTE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `solicitudes`
--

INSERT INTO `solicitudes` (`id_solicitud`, `id_donacion`, `fecha_solicitud`, `comentarios`, `estado_solicitud`) VALUES
('S1', '1', '2024-11-13 02:25:33', NULL, 'PENDIENTE');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user`
--

CREATE TABLE `user` (
  `id_user` varchar(255) NOT NULL,
  `nick_user` varchar(100) NOT NULL,
  `pass_user` varchar(255) NOT NULL,
  `email_user` varchar(100) NOT NULL,
  `tip_user` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `user`
--

INSERT INTO `user` (`id_user`, `nick_user`, `pass_user`, `email_user`, `tip_user`) VALUES
('A024YOA11', 'yato', '2772', 'alp0@gmail.com', 'admin');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `useradmin`
--

CREATE TABLE `useradmin` (
  `id_user` varchar(255) DEFAULT NULL,
  `key_admin` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `useradmin`
--

INSERT INTO `useradmin` (`id_user`, `key_admin`) VALUES
('A024YOA11', 'zzzz');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usercompany`
--

CREATE TABLE `usercompany` (
  `id_user` varchar(255) DEFAULT NULL,
  `dir_company` varchar(255) NOT NULL,
  `cell_company` int(11) NOT NULL,
  `desc_company` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `userperson`
--

CREATE TABLE `userperson` (
  `id_user` varchar(255) DEFAULT NULL,
  `name_person` varchar(100) NOT NULL,
  `doc_person` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `campania`
--
ALTER TABLE `campania`
  ADD PRIMARY KEY (`id_campania`),
  ADD KEY `id_user` (`id_user`);

--
-- Indices de la tabla `donaciones`
--
ALTER TABLE `donaciones`
  ADD PRIMARY KEY (`id_donacion`),
  ADD KEY `id_campania` (`id_campania`),
  ADD KEY `id_usuario` (`id_user`);

--
-- Indices de la tabla `solicitudes`
--
ALTER TABLE `solicitudes`
  ADD PRIMARY KEY (`id_solicitud`);

--
-- Indices de la tabla `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id_user`),
  ADD UNIQUE KEY `email_user` (`email_user`);

--
-- Indices de la tabla `useradmin`
--
ALTER TABLE `useradmin`
  ADD KEY `id_user` (`id_user`);

--
-- Indices de la tabla `usercompany`
--
ALTER TABLE `usercompany`
  ADD KEY `id_user` (`id_user`);

--
-- Indices de la tabla `userperson`
--
ALTER TABLE `userperson`
  ADD KEY `id_user` (`id_user`);

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `campania`
--
ALTER TABLE `campania`
  ADD CONSTRAINT `campania_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `user` (`id_user`);

--
-- Filtros para la tabla `donaciones`
--
ALTER TABLE `donaciones`
  ADD CONSTRAINT `donaciones_ibfk_1` FOREIGN KEY (`id_campania`) REFERENCES `campania` (`id_campania`),
  ADD CONSTRAINT `donaciones_ibfk_2` FOREIGN KEY (`id_user`) REFERENCES `user` (`id_user`);

--
-- Indices de la tabla `solicitudes`
--
ALTER TABLE `solicitudes`
  ADD CONSTRAINT `solicitudes_ibfk_2`FOREIGN KEY (`id_donacion`) REFERENCES `donaciones` (`id_donacion`);
--
-- Filtros para la tabla `useradmin`
--
ALTER TABLE `useradmin`
  ADD CONSTRAINT `useradmin_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `user` (`id_user`);

--
-- Filtros para la tabla `usercompany`
--
ALTER TABLE `usercompany`
  ADD CONSTRAINT `usercompany_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `user` (`id_user`);

--
-- Filtros para la tabla `userperson`
--
ALTER TABLE `userperson`
  ADD CONSTRAINT `userperson_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `user` (`id_user`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
