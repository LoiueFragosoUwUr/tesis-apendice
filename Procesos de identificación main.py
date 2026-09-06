    #
#//////////////////////////////////////BUSQUEDA POR CODIGO DE BARRDAS
# 
    
@app.get("/catalogoproducto/barcode/{code}", response_model=schemas.ProductoOut)
def get_producto_by_barcode(code: str, db: Session = Depends(get_db)):
    code = "".join(ch for ch in code if ch.isdigit())  # limpia espacios/guiones
    if not (8 <= len(code) <= 14):
        raise HTTPException(status_code=400, detail="Código de barras inválido")
    row = db.query(models.CatalogoProducto)\
            .filter(models.CatalogoProducto.codigo_barras == code)\
            .first()
    if not row:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return row

#//////////    BUSQUEDA POR TEXTO

# GET /catalogoproducto/search?nombre=avena
@app.get("/catalogoproducto/search", response_model=list[schemas.ProductoOut])
def search_catalogoproducto(
    nombre: str = Query(..., min_length=1),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    terms = [t for t in re.split(r"\s+", nombre.strip()) if t]
    q = db.query(models.CatalogoProducto)
    for t in terms:
        q = q.filter(models.CatalogoProducto.nombre.ilike(f"%{t}%"))
    return q.order_by(models.CatalogoProducto.nombre.asc()).limit(limit).all()

#/////////////////// busqueda por voz 
# 
class VozReq(BaseModel):
    texto: str

@app.post("/identificacion/voz", response_model=list[schemas.ProductoOut])
def identificar_por_voz(req: VozReq, limit: int = 20, db: Session = Depends(get_db)):
    q = (req.texto or "").strip()
    if not q:
        raise HTTPException(status_code=400, detail="texto requerido")
    pattern = f"%{q}%"
    rows = (
        db.query(models.CatalogoProducto)
          .filter(models.CatalogoProducto.nombre.ilike(pattern))
          .order_by(models.CatalogoProducto.nombre.asc())
          .limit(limit)
          .all()
    )
    return rows  

#/////////////////// busqueda por nombre, se usa tanto en busqueda por voz como por texto 
#/////////////////// por ser el mismo parametro

def _search_products(db: Session, nombre: str, limit: int = 30):
    nombre = (nombre or "").strip()
    if not nombre:
        return []

    # Facilita la busqueda de texto con coincidencias
    try:
        qnorm = func.unaccent(func.lower(nombre))
        fnorm = func.unaccent(func.lower(models.CatalogoProducto.nombre))
        sim = func.similarity(fnorm, qnorm)
        return (
            db.query(models.CatalogoProducto)
              .filter(sim > 0.2)              # umbral, ajusta 0.1–0.4 según gusto
              .order_by(desc(sim))
              .limit(limit)
              .all()
        )
    except Exception:
        # Fallback: PERMITE busqueda de coincidencias
        terms = [t for t in re.split(r"\s+", nombre) if t]
        q = db.query(models.CatalogoProducto)
        for t in terms:
            q = q.filter(models.CatalogoProducto.nombre.ilike(f"%{t}%"))
        return q.order_by(models.CatalogoProducto.nombre.asc()).limit(limit).all()
