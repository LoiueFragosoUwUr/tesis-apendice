import { useNavigate } from "react-router-dom";
import "./login.css";

const API = import.meta.env.VITE_API_URL ?? "http://127.0.0.1:8002";

export default function Login() {
 //Creacion de constantes para mandar a llamar datos
  const nav = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [msg, setMsg] = useState("");

  const onSubmit = async (e) => {
    e.preventDefault();
    //Creamos el acceso para nuestra sesión
    setMsg("Ingresando...");
    try {
      const res = await fetch(`${API}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      // Dispara mensaje sí las credenciales son incorrectas
      if (!res.ok) throw new Error(data?.detail ?? "Error de login");

      const token = data.token.access_token;
      localStorage.setItem("token", token);

      let fullUser = data.user;

      const resMe = await fetch(`${API}/users/me`, {
      headers: { Authorization: `Bearer ${token}` },});
      if (resMe.ok) {
      fullUser = await resMe.json();
      }

      localStorage.setItem("usertotal", JSON.stringify(fullUser));
      

      localStorage.setItem("token", data.token.access_token);
      localStorage.setItem("user", JSON.stringify(data.user));
      nav("/");
    } catch (err) {
      setMsg(err.message);
    }
  };

    return (
      // Dibujamos la pantalla del Login, tambien se mandan a llamar contenedor y clases CSS
      <div className="login-page"> 
        <h2 className="login-title">Sección de login</h2>

        <section className="card">
          <h1>Iniciar sesión</h1>
          <form onSubmit={onSubmit}>
            <div className="mb-3">
              <label className="label">Usuario</label>
              <input
                className="input"
                type="email"
                value={email}
                onChange={(e)=>setEmail(e.target.value)}
                required
                placeholder="tucorreo@mail.com"
              />
            </div>
            <div className="mb-3">
              <label className="label">Contraseña</label>
              <input
                className="input"
                type="password"
                value={password}
                onChange={(e)=>setPassword(e.target.value)}
                required
                placeholder="••••••••"
              />
            </div>
            <button className="btn" type="submit">Ingresar</button>
          </form>
          {msg && <p className="msg">{msg}</p>}
        </section>
      </div>
    );
}

\end{lstlisting}


\begin{lstlisting}[language=Python, caption={Archivo Home Home.jsx},label={tab:home_frontend_web}]
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import "./home.css";

export default function Home() {
  //Creacion de constantes para mandar a llamar datos
  const nav = useNavigate();
  const [user, setUser] = useState(null);
  const [atenciones, setAtenciones] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [usuarios, setUsuarios] = useState([]);
  const [uLoading, setULoading] = useState(false);
  const [uError, setUError] = useState("");

  const API = import.meta.env.VITE_API_URL ?? "http://127.0.0.1:8002";

  // Datos para visualizar en el encabezado
  const usertotal = JSON.parse(localStorage.getItem("usertotal") || "null");
  const name = usertotal?.nombre ?? "usuario";
  const tipousuarioid = Number(usertotal?.tipousuarioid || 0);
  const goTo = (id) => {
  const el = document.getElementById(id);
  if (el) {
    el.scrollIntoView({ behavior: "smooth", block: "start" });
    setSidebarOpen(false);
  }
};
  // Patrón useEffect para obtener el perfil provee con setUser
  useEffect(() => {
    const t = localStorage.getItem("token");
    if (!t) { nav("/login"); return; }
    (async () => {
      const r = await fetch(`${API}/users/me`, {
        headers: { Authorization: `Bearer ${t}` },
      });
      if (r.ok) {
        const me = await r.json();
        setUser(me);
        localStorage.setItem("user", JSON.stringify(me));
      } else if (r.status === 401) {
        nav("/login");
      }
    })();
  }, [API, nav]);

  // Patrón useEffect para obtener /atenciones
  useEffect(() => {
    if (!user) return;
    const t = localStorage.getItem("token");
    if (!t) return;

    const qp =
    // mostrar que tipo de usuario es
      user.tipousuarioid === 1
        ? `?paciente_id=${user.usuarioid}`
        : user.tipousuarioid === 2
        ? `?profesional_id=${user.usuarioid}`
        : "";
 
    (async () => {
      setLoading(true);
      try {
        const r = await fetch(`${API}/atenciones${qp}`, {
          headers: { Authorization: `Bearer ${t}` },
        });
        const data = await r.json();
        if (!r.ok) throw new Error(data?.detail || "Error al cargar");
        setAtenciones(data);
      } catch (e) {
        setError(e.message);
      } finally {
        setLoading(false);
      }
    })();
  }, [API, user]);

  const logout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    nav("/login");
  };


   
  useEffect(() => { 
  if (!user || user.tipousuarioid !== 2) return;   // ✅ solo profesionales
  const t = localStorage.getItem("token");
  if (!t) return;

  (async () => {
    setULoading(true); setUError(""); setUsuarios([]);
    try {
      const r = await fetch(`${API}/profesionales/me/pacientes`, {
        headers: { Authorization: `Bearer ${t}` },
      });
      if (!r.ok) throw new Error("No se pudieron cargar los pacientes");
      const data = await r.json();
      setUsuarios(data);
    } catch (e) {
      setUError(e.message || "Error cargando usuarios");
    } finally {
      setULoading(false);
    }
  })();
}, [API, user]);


const isUser1 =
  Number((user?.usuarioid ?? (usertotal?.usuarioid))) === 1;

if (isUser1) {
  return (
    <div className="special-root">
      <div className="special-canvas">
        <div className="special-title">Página principal informativa general</div>

        <section className="special-main">
          <div className="special-info">Información relevante</div>

          <div className="special-columns">
            <div className="special-card card-alimentos">
              novedades en sugerencias alimenticias
            </div>
            <div className="special-card card-fisicas">
              novedades en actividades físicas
            </div>
          </div>

          <footer className="special-footer">
            
            <span className="special-help">Instrucciones de uso del sitio</span>
            <div className="spacer" />
            <button className="special-back" onClick={() => nav(-1)}>
              Regresar
            </button>
            
          </footer>
        </section>
      </div>
    </div>
  );
}
  
  return (
    <div className="home-shell">
      <header className="home-topbar">

        <div className="home-topbar-title">
          {tipousuarioid === 1
          //muestra sí el usuario es convencional o profesional
            ? "Perfil de usuario convencional"
            : tipousuarioid === 2
            ? "Perfil de usuario profesional de la salud"
            : "Bienvenido administrador"}
        </div>
        <div className="home-topbar-right">
          <span>Sesión: <strong>{name}</strong></span>
          <button className="btn-ghost" onClick={logout}>Cerrar sesión</button>
        </div>



      </header>

      <main className="home-canvas">
        <section className="home-board">
          <h1 className="board-title">
            Información sobre usuario <strong>{name}</strong>
          </h1>
        
          {/* --- fila superior (títulos) --- */}
<div className="info-row">
  {tipousuarioid === 1 ? (
    <>
      <div className="info-box">novedades en sugerencias alimenticias</div>
      <div className="info-box">novedades en sugerencias de actividad física</div>
    </>
  ) : tipousuarioid === 2 ? (
    <>
      <div className="info-box">novedades en sugerencias alimenticias</div>
      <div className="info-box">novedades en sugerencias de actividad física</div>
    </>
  ) : (
    <>
      <div className="info-box">Opciones para administrador</div>
      <div className="info-box">Medio gráfico de selección</div>
    </>
  )}
</div>
  
{/* seteamos los paneles y las secciones de info

*/}
<div className={`content-row ${tipousuarioid != 3 ? "" : "one-col"}`}>
  {/* cuadros blancos */}
  {tipousuarioid !== 3 && <div className="panel-blanco" />}
  {tipousuarioid !== 3 && <div className="chart-wrap" />}

  {/* lista de atenciones */}
  <div className="table-wrap atenciones-list">
    {/* .Contenido */}
  </div>

  {/* tabla de usuarios/pacientes → ancho de dos columnas */}
  {tipousuarioid === 2 && (
    <div className="table-wrap full">
    
      {/* tabla actual... */}
    </div>
  )}


  {/* Lista de atenciones (ocupa la columna izq / toda la fila cuando one-col) */}
  

  {/* Solo para profesional (2) */}
  {tipousuarioid === 2 && (
    <div className="table-wrap">
      <h2>Usuarios/Pacientes</h2>
      {uLoading && <p>Cargando usuarios…</p>}
      {uError && <p>{uError}</p>}
      {!uLoading && !uError && (
        <table className="table">
          <thead>
            <tr>
              <th>#</th><th>Nombre</th><th>Email</th><th>ID</th>
            </tr>
          </thead>
          <tbody>
            {usuarios.map((u, i) => (
              <tr key={u.usuarioid ?? `${u.email}-${i}`}>
                <td>{i + 1}</td>
                <td>{u.nombre ?? u.fullname ?? "—"}</td>
                <td>{u.email ?? "—"}</td>
                <td>{u.usuarioid ?? "—"}</td>
              </tr>
            ))}
            {usuarios.length === 0 && (
              <tr><td colSpan={4}>Sin usuarios asignados</td></tr>
            )}
          </tbody>
        </table>
      )}
    </div>
    
  )}

</div>



          <footer className="board-footer">
            <div className="table-wrap atenciones-list">
    {loading && <p>Cargando…</p>}
    {error && <p>{error}</p>}
    {!loading && !error && atenciones.map(a => (
      <div key={a.atencionid}>
        {a.estado} · {new Date(a.fecha_inicio).toLocaleString()}
      </div>
    ))}
  </div>


<div className="spacer" />


             <div className="help-text">Instrucciones de uso del sitio</div>

  
  <div className="spacer" />

  
          {tipousuarioid === 3 && (
    <button className="btn-ghost" onClick={() => nav('/admin')}>
  Ir al panel de administración
</button>
  )}

          <button className="btn-ghost" onClick={() => nav(-1)}>Regresar</button>

          </footer>
        </section>
      </main>
    </div>
  );

  

}
