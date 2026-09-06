    BEGIN;


CREATE TABLE IF NOT EXISTS public.administrador
(
    user_id bigint NOT NULL,
    administradorid bigserial NOT NULL,
    CONSTRAINT pk_administrador PRIMARY KEY (administradorid),
    CONSTRAINT uq_administrador_user UNIQUE (user_id)
);

CREATE TABLE IF NOT EXISTS public.administrador_actividad_fisica
(
    administradorid bigint NOT NULL,
    actividadid bigint NOT NULL,
    CONSTRAINT administrador_actividad_fisica_pkey PRIMARY KEY (administradorid, actividadid)
);

CREATE TABLE IF NOT EXISTS public.atencion
(
    atencionid bigserial NOT NULL,
    usuario_paciente_id bigint NOT NULL,
    profesional_user_id bigint NOT NULL,
    fecha_inicio timestamp with time zone DEFAULT now(),
    estado text COLLATE pg_catalog."default",
    notas text COLLATE pg_catalog."default",
    CONSTRAINT atencion_pkey PRIMARY KEY (atencionid)
);

CREATE TABLE IF NOT EXISTS public.catalogo_actividad_fisica
(
    actividadid bigserial NOT NULL,
    nombre text COLLATE pg_catalog."default" NOT NULL,
    administradorid bigint,
    link text COLLATE pg_catalog."default",
    descripcion text COLLATE pg_catalog."default",
    categoriaid integer,
    CONSTRAINT catalogo_actividad_fisica_pkey PRIMARY KEY (actividadid),
    CONSTRAINT catalogo_categoria_unique UNIQUE (categoriaid)
);

CREATE TABLE IF NOT EXISTS public.catalogo_producto
(
    productoid bigint NOT NULL DEFAULT nextval('catalogoproducto_productoid_seq'::regclass),
    nombre text COLLATE pg_catalog."default" NOT NULL,
    administradorid bigint NOT NULL,
    esultraprocesado boolean NOT NULL DEFAULT false,
    descripcion text COLLATE pg_catalog."default",
    codigo_barras text COLLATE pg_catalog."default" NOT NULL,
    categoriaid smallint,
    marcaid bigint,
    CONSTRAINT catalogoproducto_pkey PRIMARY KEY (productoid),
    CONSTRAINT uq_catalogoproducto_codigo UNIQUE (codigo_barras)
);

CREATE TABLE IF NOT EXISTS public.catalogocedulaprofesional
(
    cedulaprofesionalid bigserial NOT NULL,
    cedulaprofesional text COLLATE pg_catalog."default" NOT NULL,
    validado boolean NOT NULL DEFAULT false,
    CONSTRAINT catalogocedulaprofesional_pkey PRIMARY KEY (cedulaprofesionalid),
    CONSTRAINT uq_catalogocedulaprofesional UNIQUE (cedulaprofesional)
);

CREATE TABLE IF NOT EXISTS public.categoria_actividad_fisica
(
    categoriaid serial NOT NULL,
    categoria text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT categoria_actividad_fisica_pkey PRIMARY KEY (categoriaid),
    CONSTRAINT categoria_actividad_fisica_categoria_key UNIQUE (categoria)
);

CREATE TABLE IF NOT EXISTS public.categoria_producto
(
    categoriaid smallserial NOT NULL,
    categoria text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT categoria_producto_pkey PRIMARY KEY (categoriaid),
    CONSTRAINT categoria_producto_categoria_key UNIQUE (categoria)
);

CREATE TABLE IF NOT EXISTS public.encuesta
(
    encuestaid bigserial NOT NULL,
    usuarioid bigint NOT NULL,
    preguntas jsonb NOT NULL,
    fecha timestamp with time zone NOT NULL DEFAULT now(),
    respuestas jsonb,
    CONSTRAINT encuesta_pkey PRIMARY KEY (encuestaid)
);

CREATE TABLE IF NOT EXISTS public.especialidad
(
    especialidadid smallserial NOT NULL,
    especialidad text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT especialidad_pkey PRIMARY KEY (especialidadid),
    CONSTRAINT especialidad_especialidad_key UNIQUE (especialidad)
);

CREATE TABLE IF NOT EXISTS public.expediente
(
    expedienteid bigserial NOT NULL,
    usuarioid bigint NOT NULL,
    fecha date,
    CONSTRAINT expediente_pkey PRIMARY KEY (expedienteid),
    CONSTRAINT expediente_usuarioid_key UNIQUE (usuarioid)
);

CREATE TABLE IF NOT EXISTS public.marca
(
    marcaid bigserial NOT NULL,
    nombre citext COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT marca_pkey PRIMARY KEY (marcaid),
    CONSTRAINT marca_nombre_key UNIQUE (nombre)
);

CREATE TABLE IF NOT EXISTS public.preferencia_difusa
(
    variableid bigserial NOT NULL,
    usuarioid bigint NOT NULL,
    nombre text COLLATE pg_catalog."default" NOT NULL,
    descripcion text COLLATE pg_catalog."default",
    universo_min numeric(10, 3) NOT NULL,
    universo_max numeric(10, 3) NOT NULL,
    valor numeric(10, 3) NOT NULL,
    CONSTRAINT preferencia_difusa_pkey PRIMARY KEY (variableid),
    CONSTRAINT preferencia_difusa_usuarioid_nombre_key UNIQUE (usuarioid, nombre)
);

CREATE TABLE IF NOT EXISTS public.profesional_con_profesional
(
    profesional_src_id bigint NOT NULL,
    profesional_dst_id bigint NOT NULL,
    vigente_desde timestamp with time zone NOT NULL DEFAULT now(),
    vigente_hasta timestamp with time zone,
    CONSTRAINT profesional_con_profesional_pkey PRIMARY KEY (profesional_src_id, profesional_dst_id, vigente_desde)
);

CREATE TABLE IF NOT EXISTS public.profesionalsalud
(
    user_id bigint NOT NULL,
    especialid smallint,
    cedulaprofesionalid bigint,
    CONSTRAINT profesionalsalud_pkey PRIMARY KEY (user_id),
    CONSTRAINT uq_ps_cedulaprofesionalid UNIQUE (cedulaprofesionalid)
);

CREATE TABLE IF NOT EXISTS public.progreso
(
    progreso_id bigserial NOT NULL,
    usuario_id bigint NOT NULL,
    fecha_medicion timestamp with time zone NOT NULL DEFAULT now(),
    comentarios text COLLATE pg_catalog."default",
    CONSTRAINT progreso_pkey PRIMARY KEY (progreso_id),
    CONSTRAINT uq_progreso_usuario_fecha UNIQUE (usuario_id, fecha_medicion)
);

CREATE TABLE IF NOT EXISTS public.sugerencia
(
    sugerenciaid bigserial NOT NULL,
    fecha_sugerencia timestamp with time zone NOT NULL DEFAULT now(),
    puntuacion_difusa real NOT NULL DEFAULT 0,
    titulo text COLLATE pg_catalog."default",
    descripcion text COLLATE pg_catalog."default",
    fuente text COLLATE pg_catalog."default",
    tiposugerenciaid smallint,
    CONSTRAINT sugerencia_pkey PRIMARY KEY (sugerenciaid)
);

CREATE TABLE IF NOT EXISTS public.sugerencia_producto
(
    sugerenciaid bigint NOT NULL,
    productoid bigint NOT NULL,
    CONSTRAINT sugerencia_producto_pkey PRIMARY KEY (sugerenciaid, productoid)
);

CREATE TABLE IF NOT EXISTS public.tipo_sugerencia
(
    tiposugerenciaid smallserial NOT NULL,
    tipo text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT tipo_sugerencia_pkey PRIMARY KEY (tiposugerenciaid),
    CONSTRAINT tipo_sugerencia_tipo_key UNIQUE (tipo)
);

CREATE TABLE IF NOT EXISTS public.tipousuario
(
    tipousuarioid smallserial NOT NULL,
    code text COLLATE pg_catalog."default" NOT NULL,
    nombrecategoriausuario text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT tipousuario_pkey PRIMARY KEY (tipousuarioid),
    CONSTRAINT tipousuario_code_key UNIQUE (code)
);

CREATE TABLE IF NOT EXISTS public.usuario
(
    usuarioid bigserial NOT NULL,
    email citext COLLATE pg_catalog."default" NOT NULL,
    password_hash text COLLATE pg_catalog."default" NOT NULL,
    nombre text COLLATE pg_catalog."default",
    tipousuarioid smallint NOT NULL,
    nombres text COLLATE pg_catalog."default",
    apellido_paterno text COLLATE pg_catalog."default",
    apellido_materno text COLLATE pg_catalog."default",
    fecha_registro date,
    alergias text COLLATE pg_catalog."default",
    condicion_medica text COLLATE pg_catalog."default",
    peso_kg numeric(5, 2),
    altura_m numeric(3, 2),
    cintura_cm numeric(5, 2),
    cadera_cm numeric(5, 2),
    CONSTRAINT usuario_pkey PRIMARY KEY (usuarioid),
    CONSTRAINT usuario_email_key UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS public.usuario_actividad
(
    usuarioid bigint NOT NULL,
    actividadid bigint NOT NULL,
    fecha_asignacion timestamp with time zone NOT NULL DEFAULT now(),
    estado text COLLATE pg_catalog."default" NOT NULL DEFAULT 'activa'::text,
    notas text COLLATE pg_catalog."default"
);

ALTER TABLE IF EXISTS public.administrador
    ADD CONSTRAINT administrador_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS uq_administrador_user
    ON public.administrador(user_id);


ALTER TABLE IF EXISTS public.administrador
    ADD CONSTRAINT fk_administrador_user FOREIGN KEY (user_id)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS uq_administrador_user
    ON public.administrador(user_id);


ALTER TABLE IF EXISTS public.administrador_actividad_fisica
    ADD CONSTRAINT fk_aaf_act FOREIGN KEY (actividadid)
    REFERENCES public.catalogo_actividad_fisica (actividadid) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_aaf_actividadid
    ON public.administrador_actividad_fisica(actividadid);


ALTER TABLE IF EXISTS public.administrador_actividad_fisica
    ADD CONSTRAINT fk_aaf_admin FOREIGN KEY (administradorid)
    REFERENCES public.administrador (administradorid) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS public.atencion
    ADD CONSTRAINT atencion_profesional_user_id_fkey FOREIGN KEY (profesional_user_id)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS ix_atencion_profesional
    ON public.atencion(profesional_user_id);


ALTER TABLE IF EXISTS public.atencion
    ADD CONSTRAINT atencion_usuario_paciente_id_fkey FOREIGN KEY (usuario_paciente_id)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS ix_atencion_paciente
    ON public.atencion(usuario_paciente_id);


ALTER TABLE IF EXISTS public.catalogo_actividad_fisica
    ADD CONSTRAINT catalogo_actividad_fisica_administradorid_fkey FOREIGN KEY (administradorid)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE SET NULL;


ALTER TABLE IF EXISTS public.catalogo_actividad_fisica
    ADD CONSTRAINT catalogo_categoria_fk FOREIGN KEY (categoriaid)
    REFERENCES public.categoria_actividad_fisica (categoriaid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS catalogo_categoria_unique
    ON public.catalogo_actividad_fisica(categoriaid);


ALTER TABLE IF EXISTS public.catalogo_producto
    ADD CONSTRAINT catalogo_prod_admin_fk FOREIGN KEY (administradorid)
    REFERENCES public.administrador (administradorid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_catalogoproducto_admin
    ON public.catalogo_producto(administradorid);


ALTER TABLE IF EXISTS public.catalogo_producto
    ADD CONSTRAINT catalogo_prod_categoria_fk FOREIGN KEY (categoriaid)
    REFERENCES public.categoria_producto (categoriaid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS catalogo_prod_categoria_idx
    ON public.catalogo_producto(categoriaid);


ALTER TABLE IF EXISTS public.catalogo_producto
    ADD CONSTRAINT catalogo_prod_marca_fk FOREIGN KEY (marcaid)
    REFERENCES public.marca (marcaid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS catalogo_prod_marca_idx
    ON public.catalogo_producto(marcaid);


ALTER TABLE IF EXISTS public.catalogo_producto
    ADD CONSTRAINT catalogo_producto_categoria_fk FOREIGN KEY (categoriaid)
    REFERENCES public.categoria_producto (categoriaid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS catalogo_prod_categoria_idx
    ON public.catalogo_producto(categoriaid);


ALTER TABLE IF EXISTS public.catalogo_producto
    ADD CONSTRAINT catalogo_producto_marca_fk FOREIGN KEY (marcaid)
    REFERENCES public.marca (marcaid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS catalogo_prod_marca_idx
    ON public.catalogo_producto(marcaid);


ALTER TABLE IF EXISTS public.catalogo_producto
    ADD CONSTRAINT fk_catalogoproducto_admin FOREIGN KEY (administradorid)
    REFERENCES public.administrador (administradorid) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS idx_catalogoproducto_admin
    ON public.catalogo_producto(administradorid);


ALTER TABLE IF EXISTS public.encuesta
    ADD CONSTRAINT encuesta_usuarioid_fkey FOREIGN KEY (usuarioid)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS encuesta_usuarioid_idx
    ON public.encuesta(usuarioid);


ALTER TABLE IF EXISTS public.expediente
    ADD CONSTRAINT expediente_usuarioid_fkey FOREIGN KEY (usuarioid)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS expediente_usuarioid_key
    ON public.expediente(usuarioid);


ALTER TABLE IF EXISTS public.preferencia_difusa
    ADD CONSTRAINT preferencia_difusa_usuarioid_fkey FOREIGN KEY (usuarioid)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS pref_usuario_idx
    ON public.preferencia_difusa(usuarioid);


ALTER TABLE IF EXISTS public.profesional_con_profesional
    ADD CONSTRAINT profesional_con_profesional_profesional_dst_id_fkey FOREIGN KEY (profesional_dst_id)
    REFERENCES public.profesionalsalud (user_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_pcp_dst
    ON public.profesional_con_profesional(profesional_dst_id);


ALTER TABLE IF EXISTS public.profesional_con_profesional
    ADD CONSTRAINT profesional_con_profesional_profesional_src_id_fkey FOREIGN KEY (profesional_src_id)
    REFERENCES public.profesionalsalud (user_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_pcp_src
    ON public.profesional_con_profesional(profesional_src_id);


ALTER TABLE IF EXISTS public.profesionalsalud
    ADD CONSTRAINT fk_ps_cedula FOREIGN KEY (cedulaprofesionalid)
    REFERENCES public.catalogocedulaprofesional (cedulaprofesionalid) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS uq_ps_cedulaprofesionalid
    ON public.profesionalsalud(cedulaprofesionalid);


ALTER TABLE IF EXISTS public.profesionalsalud
    ADD CONSTRAINT profesionalsalud_especialidad_fk FOREIGN KEY (especialid)
    REFERENCES public.especialidad (especialidadid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS idx_profesionalsalud_especialid
    ON public.profesionalsalud(especialid);


ALTER TABLE IF EXISTS public.profesionalsalud
    ADD CONSTRAINT profesionalsalud_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS profesionalsalud_pkey
    ON public.profesionalsalud(user_id);


ALTER TABLE IF EXISTS public.progreso
    ADD CONSTRAINT progreso_usuario_id_fkey FOREIGN KEY (usuario_id)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_progreso_usuario
    ON public.progreso(usuario_id);


ALTER TABLE IF EXISTS public.sugerencia
    ADD CONSTRAINT sugerencia_tiposug_fk FOREIGN KEY (tiposugerenciaid)
    REFERENCES public.tipo_sugerencia (tiposugerenciaid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE RESTRICT;


ALTER TABLE IF EXISTS public.sugerencia_producto
    ADD CONSTRAINT fk_sp_producto FOREIGN KEY (productoid)
    REFERENCES public.catalogo_producto (productoid) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS public.sugerencia_producto
    ADD CONSTRAINT fk_sp_sugerencia FOREIGN KEY (sugerenciaid)
    REFERENCES public.sugerencia (sugerenciaid) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS public.usuario
    ADD CONSTRAINT usuario_tipousuarioid_fkey FOREIGN KEY (tipousuarioid)
    REFERENCES public.tipousuario (tipousuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS public.usuario_actividad
    ADD CONSTRAINT usuario_actividad_actividadid_fkey FOREIGN KEY (actividadid)
    REFERENCES public.catalogo_actividad_fisica (actividadid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


ALTER TABLE IF EXISTS public.usuario_actividad
    ADD CONSTRAINT usuario_actividad_usuarioid_fkey FOREIGN KEY (usuarioid)
    REFERENCES public.usuario (usuarioid) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE CASCADE;

END;
