    # app/main.py
from fastapi import FastAPI, APIRouter, Depends, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from .database import *
from . import schemas
from .models import Usuario, Atencion
from .security import verify_password, create_access_token, get_current_user

#/////////////////// FastAPI app ///////////////////
app = FastAPI(title="Auth API", version="1.0.0")

# CORS son usados para frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ///////////////// Schemas ////////////////////
class LoginIn(BaseModel):# Lo que el cliente envía en el login
    email: EmailStr
    password: str

class TokenOut(BaseModel):# Token de salida es lo que devolvemos tras Login
    access_token: str
    token_type: str = "bearer"

class UserOut(BaseModel):# Datos mínimos del usuario que devolvemos
    usuarioid: int
    email: EmailStr

class AuthResponse(BaseModel):# Respuesta completa del login (token + usuario)
    token: TokenOut
    user: UserOut

# ////////////////// Router ////////////////////
auth = APIRouter(prefix="/auth", tags=["auth"])

@auth.post("/login", response_model=AuthResponse)
def login(payload: LoginIn, db: Session = Depends(get_db)):
    # 1) Buscar usuario por email
    user = db.query(Usuario).filter(Usuario.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales inválidas")

    # 2) Verificar contraseña
    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales inválidas")

    # 3) Crear JWT
    token = create_access_token(
        subject=str(user.usuarioid),
        extra={"email": user.email}  # agrega claims que te sirvan (p.ej. rol/tipo)
    )

    # 4) Responder
    return {
        "token": {"access_token": token, "token_type": "bearer"},
        "user": {"usuarioid": user.usuarioid, "email": user.email},
    }

# ///////////////// Utilidades ////////////////////
@app.get("/", include_in_schema=False)
def root():
    return {"status": "ok", "docs": "/docs"}

# Instala routers
app.include_router(auth) # Incluye el router de auth en la app principal


    token = create_access_token(subject=str(user.usuarioid), extra={"email": user.email})

    return {
        "token": {"access_token": token, "token_type": "bearer"},
        "user": {"usuarioid": user.usuarioid, "email": user.email, "nombre": getattr(user, "nombre", None)},
        "message": f"¡Bienvenido, {display_name}!"
    }
###///////////////////////// OBTIENE PERFIL COMLETO
# Devuelve el usuario completo (según tu schemas.UserOut) usando el token
@app.get("/users/me", response_model=schemas.UserOut)
def read_me(current_user: Usuario = Depends(get_current_user)):
    return current_user    


###////////////////////////// obtiene atenciones
@app.get("/atenciones", response_model=list[schemas.AtencionOut])
def list_atenciones(
     # Filtra por paciente o por profesional 
    paciente_id: int | None = None,
    profesional_id: int | None = None,
    limit: int = Query(50, le=200),
    offset: int = 0,
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):  # Crea consulta base
    q = db.query(Atencion)
    if paciente_id is None and profesional_id is None:
        if current_user.tipousuarioid == 1:
            q = q.filter(Atencion.usuario_paciente_id == current_user.usuarioid)
        elif current_user.tipousuarioid == 2:
            q = q.filter(Atencion.profesional_user_id == current_user.usuarioid)
    else:
        if paciente_id is not None:
            q = q.filter(Atencion.usuario_paciente_id == paciente_id)
        if profesional_id is not None:
            q = q.filter(Atencion.profesional_user_id == profesional_id)
    return q.order_by(Atencion.fecha_inicio.desc()).offset(offset).limit(limit).all()

#/////////////////// Detalle de una atención ///////////////////
@app.get("/atenciones/{atencionid}", response_model=schemas.AtencionOut)
def get_atencion(
    atencionid: int,
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user),
):  # Busca la atención por ID
    row = db.get(Atencion, atencionid)
    
    # Reglas simples de acceso,para que el usuario solo ve lo suyo
    if not row:
        raise HTTPException(status_code=404, detail="Atención no encontrada")
    if current_user.tipousuarioid == 1 and row.usuario_paciente_id != current_user.usuarioid:
        raise HTTPException(status_code=403, detail="Sin acceso")
    if current_user.tipousuarioid == 2 and row.profesional_user_id != current_user.usuarioid:
        raise HTTPException(status_code=403, detail="Sin acceso")
    return row
