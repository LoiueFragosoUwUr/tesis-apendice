    ###  Crea la aplicación ASGI que sirve Uvicorn. Define metadatos (título) y habilita docs en /docs y /redoc.
app = FastAPI(title="Auth mínimo")


# CORS simple la usamos para flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# Se inicializa con la aplicación
@app.on_event("startup")
def on_startup():
    # En caso de no existir lo crea
    Base.metadata.create_all(bind=engine)

############################  Helpers 
def get_tipo_by_code(db: Session, code: str) -> TipoUsuario | None:
    return db.query(TipoUsuario).filter(TipoUsuario.code == code).first()

def to_user_out(u: Usuario) -> UserOut:
    full = " ".join(
        p.strip() for p in [u.nombres, u.apellido_paterno, u.apellido_materno]
        if p and p.strip()
    )
    if not full:
        full = (u.nombre or "").strip()
    return UserOut(
        usuarioid=u.usuarioid,
        email=u.email,
        tipo_usuario=u.tipo.code if u.tipo else "",
        nombres=u.nombres,
        apellido_paterno=u.apellido_paterno,
        apellido_materno=u.apellido_materno,
        nombre_completo=full,
    )

# ---- Rutas ----
@app.get("/tipos-usuario", response_model=list[str])
def listar_tipos_usuario(db: Session = Depends(get_db)):
    rows = db.query(TipoUsuario).all()
    return [r.code for r in rows]

@app.post("/auth/register", response_model=UserOut, status_code=201)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    # En esta parte se valida el tipo de usuario
    tipo = get_tipo_by_code(db, payload.tipo_usuario)
    if not tipo:
        raise HTTPException(status_code=400, detail="tipo_usuario inválido")

    # Se realiza la concatenación para el nombre completo
    full_name = " ".join(
        s.strip() for s in [
            payload.nombres,
            payload.apellido_paterno,
            payload.apellido_materno,
        ] if s and s.strip()
    )
