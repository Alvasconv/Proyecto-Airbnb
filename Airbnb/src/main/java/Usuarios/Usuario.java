/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package Usuarios;

import SistemaInterno.Alojamiento;
import java.util.Objects;
import java.util.Scanner;

/**
 *
 * @author vv
 */
public abstract class Usuario {
    
    protected int usuarioID;
    protected String contrasenia;
    protected String nombre;
    protected String correo;
    protected String telefono;
    protected String direccionFisica;
    protected boolean verificacion;

    
    public Usuario(int usuarioID, String contrasenia, String nombre, String correo, String telefono,String direccionFisica, boolean verificacion) {
        this.usuarioID =usuarioID;
        this.contrasenia = contrasenia;
        this.nombre = nombre;
        this.correo = correo;
        this.telefono = telefono;
        this.direccionFisica= direccionFisica;
        this.verificacion = verificacion;
    }

    public Usuario(int usuarioID, String contrasenia) {
        this.usuarioID = usuarioID;
        this.contrasenia = contrasenia;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        final Usuario other = (Usuario) obj;
        
        return other.usuarioID==(this.usuarioID) && other.contrasenia.equals(this.contrasenia);
    }

    public int getUsuarioID() {
        return usuarioID;
    }

    public String getContrasenia() {
        return contrasenia;
    }
    
    public String getNombre() {
        return nombre;
    }
    
    public abstract void menuUsuario();

    @Override
    public String toString() {
        return "" + "usuarioID=" + usuarioID + ", contrasenha=" + contrasenia + ", nombre=" + nombre + ", correo=" + correo + ", telefono=" + telefono + ", direccionFisica=" + direccionFisica + ", verificacion=" + verificacion + ')';
    }
    
   
   
}
