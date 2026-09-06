##############                 PROVEE DE LA LISTA DE PROFESIONALES DE LA SALUD

@app.get("/profesionales", response_model=list[schemas.ProfesionalLite], tags=["profesionales"])
def listar_profesionales(
    q: str | None = Query(None, description="Buscar por nombre, cédula o especialidad"),
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db),
):
    query = (
        db.query(models.Usuario, models.ProfesionalSalud)
        .join(models.ProfesionalSalud, models.ProfesionalSalud.user_id == models.Usuario.usuarioid)
        .filter(models.Usuario.tipousuarioid == 2)   # solo profesionales
    )
    

    if q:
        like = f"%{q}%"
        query = query.filter(or_(
            models.Usuario.nombres.ilike(like),
            models.Usuario.apellido_paterno.ilike(like),
            models.Usuario.apellido_materno.ilike(like),
            models.ProfesionalSalud.cedulaprofesional.ilike(like),
            models.ProfesionalSalud.especialidad.ilike(like),
        ))

    filas = (query
             .order_by(models.Usuario.apellido_paterno, models.Usuario.apellido_materno, models.Usuario.nombres)
             .limit(limit).offset(offset).all())

    return [
        schemas.ProfesionalLite(
            user_id=ps.user_id,
            nombre_completo=f"{u.nombres} {u.apellido_paterno} {u.apellido_materno}".strip(),
            cedulaprofesional=ps.cedulaprofesional,
            especialidad=ps.especialidad,
            
        )
        for (u, ps) in filas
    ]
