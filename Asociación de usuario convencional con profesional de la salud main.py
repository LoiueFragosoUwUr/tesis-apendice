    ################         CREA ASOCIACIÓN DE USUARIO CONVENTIONAL A PROFESSIONAL


@app.post("/atencion", response_model=schemas.AtencionOut, tags=["atencion"])
def crear_atencion(
    payload: schemas.AtencionCreate,
    db: Session = Depends(get_db),
    user: models.Usuario = Depends(get_current_user),
):
    # regla simple: el que crea la asociación es el usuario conventional
    if user.tipousuarioid != 1:  # usuario  categoria 1 = conventional
        raise HTTPException(status_code=403, detail="Solo pacientes pueden crear la atención")

    # validar que el profesional exista
    prof = db.query(models.ProfesionalSalud).get(payload.profesional_user_id)
    if not prof:
        raise HTTPException(status_code=404, detail="Profesional no encontrado")

    # Evita duplicado activo
    dup = (
        db.query(models.Atencion)
        .filter(
            models.Atencion.usuario_paciente_id == user.usuarioid,
            models.Atencion.profesional_user_id == payload.profesional_user_id,
            models.Atencion.estado == "activo",
        )
        .first()
    )
    if dup:
        raise HTTPException(status_code=409, detail="Ya existe una atención activa con este profesional")

    att = models.Atencion(
        usuario_paciente_id=user.usuarioid,
        profesional_user_id=payload.profesional_user_id,
        fecha_inicio=payload.fecha_inicio or datetime.utcnow(),
        estado=payload.estado or "activo",
        notas=payload.notas,
    )
    db.add(att)
    db.commit()
    db.refresh(att)
    return att
