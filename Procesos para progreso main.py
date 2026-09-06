    ####################                REGISTRA PROGRESO  hace uso del token


@app.post("/progreso", response_model=schemas.ProgresoOut, tags=["progreso"])
def crear_progreso(payload: schemas.ProgresoCreate,
                   db: Session = Depends(get_db),
                   user: models.Usuario = Depends(get_current_user)):
    prog = models.Progreso(
        usuario_id=user.usuarioid,
        fecha_medicion=payload.fecha_medicion or datetime.utcnow(),
        peso_kg=payload.peso_kg,
        altura_m=payload.altura_m,
        cintura_cm=payload.cintura_cm,
        cadera_cm=payload.cadera_cm,
        comentarios=payload.comentarios,
    )
    db.add(prog)
    db.commit()
    db.refresh(prog)
    return prog


###################                    OBTIENE EL ID DEL PROGRESO

@app.get("/progreso/{progreso_id}", response_model=schemas.ProgresoOut, tags=["progreso"])
def leer_progreso(progreso_id: int,
                  db: Session = Depends(get_db),
                  user: models.Usuario = Depends(get_current_user)):
    prog = db.query(models.Progreso).get(progreso_id)
    if not prog:
        raise HTTPException(status_code=404, detail="No encontrado")
    if prog.usuario_id != user.usuarioid:
        raise HTTPException(status_code=403, detail="Prohibido")
    return prog

###################         ACTUALIZA ID DEL PROGRESO

@app.put("/progreso/{progreso_id}", response_model=schemas.ProgresoOut, tags=["progreso"])
def actualizar_progreso(progreso_id: int,
                        payload: schemas.ProgresoUpdate,
                        db: Session = Depends(get_db),
                        user: models.Usuario = Depends(get_current_user)):
    prog = db.query(models.Progreso).get(progreso_id)
    if not prog:
        raise HTTPException(status_code=404, detail="No encontrado")
    if prog.usuario_id != user.usuarioid:
        raise HTTPException(status_code=403, detail="Prohibido")

    for campo, valor in payload.dict(exclude_unset=True).items():
        setattr(prog, campo, valor)
    if not payload.fecha_medicion:
        # SE MANTIENE FECHA EXISTENTE  necesita cambios
        pass
    db.commit()
    db.refresh(prog)
    return prog
