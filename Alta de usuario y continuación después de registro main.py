        # Se agrega el usuario a la base de datos con el marco indicado
    user = Usuario(
        email=payload.email,
        password_hash=get_password_hash(payload.password),
        nombres=payload.nombres,
        apellido_paterno=payload.apellido_paterno,
        apellido_materno=payload.apellido_materno,
        nombre=full_name,              # Esto concatena al nombre completo      
        tipousuarioid=tipo.tipousuarioid,
    )
    db.add(user)
    try:
        db.flush()  # genera usuarioid
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El email ya está registrado")

    # En el caso de ser professional, crear registro en profesionalsalud
    if tipo.code == "professional":
        db.add(ProfesionalSalud(
            user_id=user.usuarioid,
            cedulaprofesional=payload.cedula,
            especialidad=payload.especialidad,
        ))

    db.commit()
    db.refresh(user)
    return to_user_out(user)
