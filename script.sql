drop database if exists airbnb;
create database airbnb;
use airbnb;

CREATE TABLE ubicacion(
	ubicacion_id int primary KEY,
	pais VARCHAR(50) default "Ecuador",
	ciudad VARCHAR(50) NOT null
);
CREATE INDEX idx_pais ON ubicacion(pais);

-- drop table if exists cliente;
CREATE TABLE cliente (
    usuario_id INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    contrasenia VARCHAR(100) NOT NULL,
    telefono VARCHAR(15),
    correo VARCHAR(100),
    direccion_fisica VARCHAR(200),
    verificador BOOLEAN default false
);

-- drop table if exists anfitrion;
CREATE TABLE anfitrion (
    usuario_id INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    contrasenia VARCHAR(100) NOT NULL,
    telefono VARCHAR(15),
    correo VARCHAR(100),
    ubicacion_id int,
    verificador BOOLEAN default true,
    FOREIGN KEY (ubicacion_id) REFERENCES ubicacion(ubicacion_id)
);

-- drop table if exists alojamiento;
CREATE TABLE alojamiento (
    alojamiento_id INT PRIMARY KEY,
    nombre varchar(40) default null,
    anfitrion_id INT,
    precio_noche DECIMAL(10, 2),
    habitaciones INT,
    ubicacion_id int,
    calificacion DECIMAL(3, 2),
    tarifa_airbnb DECIMAL(10, 2) default null,
	FOREIGN KEY (anfitrion_id) REFERENCES anfitrion(usuario_id),
    FOREIGN KEY (ubicacion_id) REFERENCES ubicacion(ubicacion_id)

);

-- drop table if exists lista_favorito;
CREATE TABLE lista_favorito(
    alojamiento_id INT,
    cliente_id INT,
    PRIMARY KEY (alojamiento_id, cliente_id),
    FOREIGN KEY (cliente_id) REFERENCES cliente(usuario_id),
    FOREIGN KEY (alojamiento_id) REFERENCES alojamiento(alojamiento_id) ON DELETE CASCADE
);

-- drop table if exists servicio_alojamiento;
CREATE TABLE servicio_alojamiento (
    alojamiento_id INT ,
    servicio_id INT  PRIMARY KEY,
    servicio VARCHAR(100) NOT NULL,
    FOREIGN KEY (alojamiento_id) REFERENCES alojamiento(alojamiento_id) ON DELETE CASCADE
);

-- drop table if exists regla_alojamiento;
CREATE TABLE regla_alojamiento (
    alojamiento_id INT,
    reglamento_id INT ,
    regla VARCHAR(100) NOT NULL,
    PRIMARY KEY ( reglamento_id),
    FOREIGN KEY (alojamiento_id) REFERENCES alojamiento(alojamiento_id) ON DELETE CASCADE
);

 drop table if exists mensaje;
CREATE TABLE mensaje (
    mensaje_id INT PRIMARY KEY,
    mensaje VARCHAR(200),
    anfitrion_id INT,
    cliente_id INT,
    FOREIGN KEY (anfitrion_id) REFERENCES anfitrion(usuario_id),
    FOREIGN KEY (cliente_id) REFERENCES cliente(usuario_id)
);

-- drop table if exists reserva;
CREATE TABLE reserva (
    reserva_id INT PRIMARY KEY ,
    cliente_id INT,
    alojamiento_id INT,
    fecha_ingreso date,
    fecha_salida date,
    FOREIGN KEY (cliente_id) REFERENCES cliente(usuario_id),
    FOREIGN KEY (alojamiento_id) REFERENCES alojamiento(alojamiento_id) ON DELETE CASCADE
);
CREATE INDEX idx_fecha_ingreso ON reserva(fecha_ingreso);
CREATE INDEX idx_fecha_salida ON reserva(fecha_salida);

 drop table if exists pago_tarjeta;
CREATE TABLE pago_tarjeta (
    pago_id INT PRIMARY KEY,
    reserva_id INT,
    monto DECIMAL(10, 2) default null,
    fecha DATE,
    numero_tarjeta INT,
    caducidad DATE,
    codigo_postal int,
    codigo_cvv smallint,
    FOREIGN KEY (reserva_id) REFERENCES reserva(reserva_id)
);

drop table if exists pago_paypal;
CREATE TABLE pago_paypal (
    pago_id INT PRIMARY KEY,
    reserva_id INT,
    monto DECIMAL(10, 2) default null,
    fecha DATE,
    numero_cuenta int,
    FOREIGN KEY (reserva_id) REFERENCES reserva(reserva_id)
);

-- drop table if exists pago_googlepay;
CREATE TABLE pago_googlepay (
    pago_id INT PRIMARY KEY,
    reserva_id INT,
    monto DECIMAL(10, 2) default null,
    fecha DATE,
    numero_cuenta int,
    FOREIGN KEY (reserva_id) REFERENCES reserva(reserva_id)
);

-- drop table if exists fechas_reservadas;
CREATE TABLE fechas_reservadas (
    fecha DATE,
    alojamiento_id INT,
    reserva_id INT,
    PRIMARY KEY (fecha, alojamiento_id, reserva_id),
    FOREIGN KEY (alojamiento_id) REFERENCES alojamiento(alojamiento_id) ON DELETE CASCADE,
    FOREIGN KEY (reserva_id) REFERENCES reserva(reserva_id)
);
CREATE INDEX idx_fecha ON fechas_reservadas(fecha);

CREATE TABLE resenia (
    cliente_id INT,
    alojamiento_id INT,
    comentario TEXT,
    calificacion DECIMAL(3, 2),
    PRIMARY KEY(cliente_id,alojamiento_id),
    FOREIGN KEY (cliente_id) REFERENCES cliente(usuario_id),
    FOREIGN KEY (alojamiento_id) REFERENCES alojamiento(alojamiento_id) ON DELETE CASCADE
);

###	PROCEDURES	##############################################################################################

drop procedure if exists fechaReservada;
DELIMITER //
create procedure consultarAlojamiento()
begin
	select *
	from alojamiento a JOIN ubicacion u ON a.ubicacion_id=u.ubicacion_id;
end //
DELIMITER ;

call consultarAlojamiento();

-- sp para comprobar si hay reservas entre las fechas realizadas por el cliente
drop procedure if exists fechaReservada;
DELIMITER //
create procedure fechaReservada(in fechaI date,in fechaS date,in alojamiento_id int,out respuesta int)
begin
	set @cantidad = (Select count(fr.fecha) 
					from fechas_reservadas fr
					where fr.fecha between fechaI and fechaS and fr.alojamiento_id=alojamiento_id);
    if (@cantidad>0) then
		select 0 into respuesta;
	else
		select 1 into respuesta;
	end if;
end//
DELIMITER ;


-- sp para insertar reseñas
DELIMITER //
CREATE PROCEDURE InsertarResenia(IN cliente_id INT, IN alojamiento_id INT, IN comentario TEXT, IN calificacion DECIMAL(3, 2) )
BEGIN
    insert into resenia(cliente_id, alojamiento_id, comentario, calificacion)
    values (cliente_id, alojamiento_id, comentario, calificacion);
END //
DELIMITER ;


-- sp alojamientos favoritos
DELIMITER //
CREATE PROCEDURE InsertarAlojamientoFavorito( IN alojamiento_id INT, IN cliente_id INT)
BEGIN
    insert into lista_favorito(alojamiento_id, cliente_id)
    values (alojamiento_id, cliente_id);
END //
DELIMITER ;

-- sp  para crear reglas de alojamiento
DELIMITER //
CREATE PROCEDURE InsertarReglaA(in alojamiento_id int, IN regla VARCHAR(100))
BEGIN
	set @reglamento_id= (select count(reglamento_id) from regla_alojamiento)+1;
    insert into regla_alojamiento(alojamiento_id, reglamento_id, regla)
    values (alojamiento_id,(select @reglamento_id), regla);
END //
DELIMITER ;

drop procedure if exists InsertarAlojamiento;
-- sp  para insertar Alojamiento
DELIMITER //
CREATE PROCEDURE InsertarAlojamiento(in anfitrion int ,in precio decimal(10,2), in habitaciones int, in pais varchar(50),in ciudad varchar(50), in tarifa_A decimal(10,2), in nombre varchar(40))
BEGIN
	DECLARE errno INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
	begin
    GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO;
    SELECT errno AS MYSQL_ERROR;
    ROLLBACK;
    end;
    start transaction;
    set @ubicacion_ind= (select count(ubicacion_id) from ubicacion)+1;
	insert into ubicacion (ubicacion_id, pais, ciudad)
				values ((select @ubicacion_ind),pais,ciudad);
    
	set @ind= (select count(alojamiento_id) from alojamiento)+1001;
    insert into alojamiento (alojamiento_id, nombre, anfitrion_id, precio_noche, habitaciones, ubicacion_id, calificacion, tarifa_airbnb)
						values((select @ind),nombre,anfitrion,precio,habitaciones,(select @ubicacion_ind),0,tarifa_A);
    commit;
END //
DELIMITER ;

-- sp  para insertar Servicios
DELIMITER //
CREATE PROCEDURE InsertarServicioA(in alojamiento_id INT, in servicio varchar(100))
BEGIN
	set @servicio_id= (select count(servicio_id) from servicio_alojamiento)+1;
    insert into servicio_alojamiento(alojamiento_id, servicio_id, servicio) 
							values(alojamiento_id,(select @servicio_id),servicio);
END //
DELIMITER ;

-- sp insertar mensajes
DELIMITER //
CREATE PROCEDURE InsertarMensaje(in mensaje varchar(200),in anfitrion_id int, in cliente_id int)
BEGIN
	set @mensaje_id= (select count(mensaje_id) from mensaje)+1;
    insert into mensaje(mensaje_id, mensaje, anfitrion_id, cliente_id) 
				 values((select @mensaje_id), mensaje, anfitrion_id, cliente_id);
END //
DELIMITER ;
set autocommit=0;
-- sp insertar Pago ----------------------------------------

 drop procedure if exists InsertarPagoTarjeta;
DELIMITER //
create procedure  InsertarPagoTarjeta(in cliente_id INT, in alojamiento_id INT,in fecha_ingreso DATE,in fecha_salida DATE,IN numero_tarjeta INT, IN caducidad DATE, IN codigo_postal int, IN codigo_cvv SMALLINT)
begin
	DECLARE errno INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
	begin
    GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO;
    SELECT errno AS MYSQL_ERROR;
    ROLLBACK;
    end;
	start transaction;
		set @indr= (select count(reserva_id) from reserva)+9001;
		insert into reserva (reserva_id, cliente_id, alojamiento_id, fecha_ingreso, fecha_salida) 
					values ((select @indr), cliente_id, alojamiento_id, fecha_ingreso, fecha_salida);
		
		set @dias = (Select datediff(fecha_salida,fecha_ingreso ));
		set @t_airbnb = (select a.tarifa_airbnb from alojamiento a where a.alojamiento_id=alojamiento_id);
		set @p_noche = (select a.precio_noche from alojamiento a where a.alojamiento_id=alojamiento_id);
		set @monto = (((select @p_noche)*(select @dias))+(select @t_airbnb));
		set @pago_id= (select count(pago_id) from pago_tarjeta)+1;
        
		insert into pago_tarjeta(pago_id, reserva_id, monto, fecha, numero_tarjeta, caducidad, codigo_postal, codigo_cvv) 
						values((select @pago_id),(select @indr),(select @monto),fecha_ingreso,numero_tarjeta,caducidad,codigo_postal,codigo_cvv);
    commit;
end //
DELIMITER ; 


 drop procedure if exists InsertarPagoGPay;
DELIMITER //
create procedure  InsertarPagoGPay(in cliente_id INT, in alojamiento_id INT,in fecha_ingreso DATE,in fecha_salida DATE,IN numeroCuenta int)
begin
	DECLARE errno INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
	begin
    GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO;
    SELECT errno AS MYSQL_ERROR;
    ROLLBACK;
    end;
    start transaction;
	set @indr= (select count(reserva_id) from reserva)+9001;
	insert into reserva (reserva_id,cliente_id, alojamiento_id, fecha_ingreso, fecha_salida) 
				values ((select @indr),cliente_id, alojamiento_id, fecha_ingreso, fecha_salida);
    
    set @dias = (Select datediff(fecha_salida,fecha_ingreso ));
    set @t_airbnb = (select a.tarifa_airbnb from alojamiento a where a.alojamiento_id=alojamiento_id);
    set @p_noche = (select a.precio_noche from alojamiento a where a.alojamiento_id=alojamiento_id);
    set @monto = (((select @p_noche)*(select @dias))+(select @t_airbnb));
    set @pago_id= (select count(pago_id) from pago_googlepay)+1;
 
    insert into pago_googlepay (pago_id, reserva_id, monto, fecha, numero_cuenta) 
						values((select @pago_id),@indr,(select @monto),fecha_ingreso,numeroCuenta);
    commit;
end //
DELIMITER ; 


 drop procedure if exists InsertarPagoPaypal;
DELIMITER //
create procedure  InsertarPagoPaypal(in cliente_id INT, in alojamiento_id INT,in fecha_ingreso DATE,in fecha_salida DATE,IN numeroCuenta int)
begin
	DECLARE errno INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
	begin
    GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO;
    SELECT errno AS MYSQL_ERROR;
    ROLLBACK;
    end;
    start transaction;
	set @indr= (select count(reserva_id) from reserva)+9001;
	insert into reserva (reserva_id,cliente_id, alojamiento_id, fecha_ingreso, fecha_salida) 
				values ((select @indr),cliente_id, alojamiento_id, fecha_ingreso, fecha_salida);
    
    set @dias = (Select datediff(fecha_salida,fecha_ingreso ));
    set @t_airbnb = (select a.tarifa_airbnb from alojamiento a where a.alojamiento_id=alojamiento_id);
    set @p_noche = (select a.precio_noche from alojamiento a where a.alojamiento_id=alojamiento_id);
    set @monto = (((select @p_noche)*(select @dias))+(select @t_airbnb));
    set @pago_id= (select count(pago_id) from pago_paypal)+1;
 
    insert into pago_paypal (pago_id, reserva_id, monto, fecha, numero_cuenta) 
					values((select @pago_id),@indr,(select @monto),fecha_ingreso,numeroCuenta);
	commit;
end //
DELIMITER ;  

################################ 	SPS UPDATES ALOJAMIENTO		 ###########################################################################

DELIMITER //
create procedure updateAlojamientoNombre(in aloj_id int,in cambio varchar(30))
begin
	UPDATE alojamiento
    set nombre = cambio
    where alojamiento_id=aloj_id;
end //
DELIMITER ;

DELIMITER //
create procedure updateAlojamientoCosto(in aloj_id int, in cambio double)
begin
	UPDATE alojamiento
    set costo_noche = cambio
    where alojamiento_id=aloj_id;
end //
DELIMITER ;

DELIMITER //
create procedure updateAlojamientoHabitacion(in aloj_id int, in cambio int)
begin
	UPDATE alojamiento
    set habitaciones = cambio
    where alojamiento_id=aloj_id;
end //
DELIMITER ;

#################	DELETE SPS	###############################################################################

-- sp borrar reserva
DELIMITER //
CREATE PROCEDURE BorrarReserva(IN reserva_id INT)
BEGIN
    DELETE FROM reserva WHERE reserva_id = reserva_id;
END //
DELIMITER ;

-- sp borrar alojamiento
drop procedure if exists BorrarAlojamiento;
DELIMITER //
CREATE PROCEDURE BorrarAlojamiento(IN aloj_id INT)
BEGIN
	DECLARE errno INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
	begin
    GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO;
    SELECT errno AS MYSQL_ERROR;
    ROLLBACK;
    end;
    start transaction;
    DELETE FROM alojamiento  WHERE alojamiento_id = aloj_id;
    
    
    commit;
END //
DELIMITER ;


-- sp borrar regla de alojamiento
DELIMITER //
CREATE PROCEDURE BorrarReglaAlojamiento(IN alojamiento_id INT, IN reglamento_id INT)
BEGIN
    DELETE FROM regla_alojamiento WHERE alojamiento_id = alojamiento_id AND reglamento_id = reglamento_id;
END //
DELIMITER ;

-- sp borrar servicio alojaminto
DELIMITER //

CREATE PROCEDURE BorrarServicioAlojamiento(IN alojamiento_id INT, IN servicio_id INT)
BEGIN
    DELETE FROM servicio_alojamiento WHERE alojamiento_id = alojamiento_id AND servicio_id = servicio_id;
END //

DELIMITER ;


##############################################################################################################
###	TRIGGERS	##############################################################################################


-- crea las fechas reservadas de forma automatica una vez se crea una reserva ----------------------------------------
 drop trigger if exists crearFechaReservada;
DELIMITER //
create trigger crearFechaReservada after insert ON reserva
for each row
begin
	declare fechaIn date;
    set fechaIn = new.fecha_ingreso;
    while (fechaIn<=new.fecha_salida) do
		insert into fechas_reservadas values(fechaIn,new.alojamiento_id,new.reserva_id);
        select DATE_ADD(fechaIn,interval 1 day) INTO fechaIn;
    end while;
end //
DELIMITER ; 


-- verifica que no se reserve en un periodo con fechas ya reservadas	--------------------------------------------
drop trigger if exists fechaEstaReservada;
DELIMITER //
create trigger fechaEstaReservada before insert on reserva
for each row
begin
    call fechaReservada(new.fecha_ingreso,new.fecha_salida,new.alojamiento_id,@reservas);
    if convert(new.fecha_ingreso,date)<=convert(new.fecha_salida,date) then
		if ((select @reservas)=0) then
			signal sqlstate '11111' set message_text='Existen fechas ya reservadas';		
		end if;
	else
		signal sqlstate '22222' set message_text='Ingreso erroneo de fechas';
	end if;
end//
DELIMITER ;

################################ VISTAS	################################################################################################

create view vistaInformacionAlojamientos
as 
	select a.nombre as nombre_alojamiento,
    u.pais,u.ciudad,
    a.precio_noche,
    d.nombre as nombre_anfitrion,
    COALESCE(AVG(rs.calificacion), 0) AS promedio_resenas
	FROM anfitrion d
	JOIN alojamiento a ON a.anfitrion_id = d.usuario_id
    JOIN ubicacion u on a.ubicacion_id = u.ubicacion_id
	LEFT JOIN resenia rs ON a.alojamiento_id = rs.alojamiento_id
    group by a.alojamiento_id;
    
create view vistaInformacionReservas
as
	select r.reserva_id, a.anfitrion_id, c.usuario_id, a.nombre as nombre_alojamiento, c.nombre as nombre_cliente, fecha_ingreso, fecha_salida, COALESCE(pt.monto, pg.monto, pp.monto) as monto_pagar
	from reserva r
	LEFT JOIN pago_paypal pp ON r.reserva_id = pp.reserva_id
	LEFT JOIN pago_googlepay pg ON r.reserva_id = pg.reserva_id
	LEFT JOIN pago_tarjeta pt ON r.reserva_id = pt.reserva_id
	INNER JOIN alojamiento a on a.alojamiento_id = r.alojamiento_id
	INNER JOIN cliente c on c.usuario_id = r.cliente_id;

create view vistaInformacionFavorito
as 
	select a.nombre as nombre_alojamiento,
			u.pais,u.ciudad,
			a.precio_noche,
			lf.cliente_id,
			d.nombre as nombre_anfitrion,
            (CASE
				WHEN (select count(fr.fecha) 
					from fechas_reservadas fr
					where fr.fecha between CURDATE() and DATE_ADD(CURDATE(), INTERVAL 1 DAY) and fr.alojamiento_id=a.alojamiento_id
					) > 0 then
						1
					else 
                        0
					end) as reservado
	from alojamiento a, lista_favorito lf, anfitrion d, ubicacion u
	where lf.alojamiento_id = a.alojamiento_id and a.anfitrion_id = d.usuario_id and u.ubicacion_id = a.ubicacion_id;

select * from vistaInformacionFavorito;

create view vistaInformacionResenia
as
	select 
		a.alojamiento_id,
		a.nombre as nombre_alojamiento,
		c.nombre as nombre_cliente,
        c.usuario_id,
        r.comentario,
        r.calificacion
	from
		alojamiento a
        join resenia r on a.alojamiento_id = r.alojamiento_id
        join cliente c on c.usuario_id = r.cliente_id;


###################	UBICACION	#############################################################################################

insert into ubicacion VALUE (1,"Ecuador","Guayaquil");
insert into ubicacion VALUE (2,"Ecuador","Ayangue");
insert into ubicacion VALUE (3,"Ecuador","Olon");
insert into ubicacion VALUE (4,"Ecuador","Quito");
insert into ubicacion VALUE (5,"Ecuador","Machala");
insert into ubicacion VALUE (6,"Colombia","Bogota");
insert into ubicacion VALUE (7,"Peru","Lima");
insert into ubicacion VALUE (8,"Ecuador","Manta");
insert into ubicacion VALUE (9,"Ecuador","Cuenca");
insert into ubicacion VALUE (10,"Ecuador","Ambato");



###	ANFITRIONES	##############################################################################################

insert into anfitrion values(10,'Luis','luisriv10','0987654321','lrivadeneira@gmail.com',1,true);
insert into anfitrion values(11,'Angel','anto11','0234567890','angeltorres@gmail.com',1,true);
insert into anfitrion values(12,'Emilia','emigomez12','0357908642','emigomez@gmail.com',1,true);
insert into anfitrion values(13,'Michelle','michip13','0029384576','michelleperalta@gmail.com',2,true);
insert into anfitrion values(14,'Dara','darat14','0281973465','daratriviño@gmail.com',2,true);
insert into anfitrion values(15,'Alejandro','alevera15','0784913473','alevera@gmail.com',2,true);
insert into anfitrion values(16,'Jostin','jossozo16','0026574893','jostinsozo@gmail.com',2,true);
insert into anfitrion values(17,'Alessandro','alemoreno17','0839465901','sandromoreno@gmail.com',3,true);
insert into anfitrion values(18,'Josseline','jossolis18','0204936173','josssolis@gmail.com',4,true);
insert into anfitrion values(19,'Camila','camileon19','07354800274','camileon@gmail.com',1,true);

###	ALOJAMIENTOS	##############################################################################################

insert into alojamiento values(1001,"TorreAG Puerto Santa Ana",10,45,3,1,4.3,12.5);
insert into alojamiento values(1002,"HT Olivos",11,80,4,1,4.8,31.3);
insert into alojamiento values(1003,"Casa Rosada GRANDE",12,70,2,2,4.4,21);
insert into alojamiento values(1004,"Casa Blanca vista al Mar",13,22,1,3,3.8,7.5);
insert into alojamiento values(1005,"Casa Rosada PEQUEÑA",14,95,4,2,4.7,18);
insert into alojamiento values(1006,"Departamento moderno",15,120,5,2,4.2,41.7);
insert into alojamiento values(1007,"Hacienda Rancho Nuevo",16,15,1,3,2.7,11.5);
insert into alojamiento values(1008,"Hacienda Prosperidad",17,35,2,5,3.3,16);
insert into alojamiento values(1009,"PH minimalista",18,55,3,1,4.2,14.3);
insert into alojamiento values(1010,"Suit moderna",19,50,3,2,3.6,11.6);

###	cLIENTES	##############################################################################################

insert into cliente values(20,'Anthony','anthonyc20','0987654321','acastro@gmail.com','Guasmo norte',false);
insert into cliente values(21,'Angello','alvancon21','0234567890','alvancon@gmail.com','Pradera 1',false);
insert into cliente values(22,'Thais','thaivillon22','0357908642','tvillon@gmail.com','Barrio Cuba',false);
insert into cliente values(23,'Shirley','shirleyc23','0029384576','scuero@gmail.com','Los almendros',false);
insert into cliente values(24,'Jonai','jjonaiv24','0281973465','jonaivargas@gmail.com','Guasmo Central',false);
insert into cliente values(25,'Abigail','abisolorza25','0784913473','abisolorzano@gmail.com','Barrio 9 de octubre',false);
insert into cliente values(26,'Jennifer','jennybu26','0026574893','jennyburbano@gmail.com','Barrio centenario',false);
insert into cliente values(27,'Paula','paugcu27','0839465901','paulagomez@gmail.com','Urbasur',false);
insert into cliente values(28,'Alexa','alexale28','0204936173','alexaleon@gmail.com','Pradera 3',false);
insert into cliente values(29,'Giuliano','giusan29','07354800274','giusanchez@gmail.com','Guasmo Sur',false);


###	RESERVACIONES	##############################################################################################

insert into reserva values(9001,20,1001,"2023-08-12","2023-08-14"); 
insert into reserva values(9002,20,1002,"2023-09-05","2023-09-11");
insert into reserva values(9003,21,1003,"2023-08-04","2023-08-17"); 
insert into reserva values(9004,20,1004,"2023-08-25","2023-08-27"); 
insert into reserva values(9005,24,1005,"2023-09-10","2023-09-10");
insert into reserva values(9006,25,1006,"2023-08-02","2023-08-05"); 
insert into reserva values(9007,20,1007,"2023-08-29","2023-09-02");
insert into reserva values(9008,22,1008,"2023-08-14","2023-08-15"); 
insert into reserva values(9009,28,1009,"2023-09-13","2023-09-21");
insert into reserva values(9010,29,1010,"2023-09-23","2023-09-24");

###	REGLAS	##############################################################################################

insert into regla_alojamiento values(1001,1,'No se permiten mascotas.');
insert into regla_alojamiento values(1001,2,'Recoger su basura antes de salir.');
insert into regla_alojamiento values(1003,3,'Mantener el aire acondiconado a una temperatura de 20 grados.');
insert into regla_alojamiento values(1004,4,'No realizar fiestas.');
insert into regla_alojamiento values(1005,5,'Prohibido fumar dentro del alojamiento.');
insert into regla_alojamiento values(1005,6,'La salida es a las 12 del mediodia.');
insert into regla_alojamiento values(1005,7,'Cualquier pedido de servicio a la habitacion se le sumara al cliente.');
insert into regla_alojamiento values(1008,8,'Evitar saltar sobre la cama.');
insert into regla_alojamiento values(1009,9,'No se puede hacer bulla despues de las 9 de la noche.');
insert into regla_alojamiento values(1010,10,'El anfitrion no se responsabiliza por perdidas u olvidos materiales.');


###	SERVICIOS	##############################################################################################

insert into servicio_alojamiento values(1001,1,'Servicio a la habitacion');
insert into servicio_alojamiento values(1005,2,'Servicio de seguridad.');
insert into servicio_alojamiento values(1003,3,'Minibar con bebidas');
insert into servicio_alojamiento values(1007,4,'Salon para fiestas.');
insert into servicio_alojamiento values(1005,5,'Servicio a la habitacion.');
insert into servicio_alojamiento values(1006,6,'Servicio de limpieza diario.');
insert into servicio_alojamiento values(1004,7,'bebidas ilimitadas del minibar');
insert into servicio_alojamiento values(1008,8,'Piscina compartida.');
insert into servicio_alojamiento values(1009,9,'Playa privada.');
insert into servicio_alojamiento values(1010,10,'Zona de acampar privado.');

###	RESEÑAS	##############################################################################################

insert into resenia values(20,1001,"Buen ambiente, vecindario tranquilo.",4.2);
insert into resenia values(21,1003,"No es lo que se ve en la pagina, lugar asqueroso.",2.3);
insert into resenia values(22,1006,"Buena atencion de parte del anfitrion, posee buena vista",4.8);
insert into resenia values(25,1008,"Muy regular, esperabalojamientoa mas",3.5);

###	FAVORITOS	##############################################################################################

insert into lista_favorito values(1001,20);
insert into lista_favorito values(1002,20);
insert into lista_favorito values(1003,23);
insert into lista_favorito values(1004,27);
insert into lista_favorito values(1005,25);
insert into lista_favorito values(1006,24);

###########################CREACION DE USUARIOS####################################

-- Crear usuarios
CREATE USER 'luisriv10'@'localhost' IDENTIFIED BY 'luisriv10';
CREATE USER 'anto11'@'localhost' IDENTIFIED BY 'anto11';
CREATE USER 'anthonyc20'@'localhost' IDENTIFIED BY 'anthonyc20';
CREATE USER 'alvancon21'@'localhost' IDENTIFIED BY 'alvancon21';
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin';

-- Dar permisos a los usuarios

GRANT INSERT, UPDATE ON airbnb.alojamiento TO 'luisriv10'@'localhost';
GRANT EXECUTE ON PROCEDURE airbnb.InsertarAlojamiento TO 'luisriv10'@'localhost';
GRANT SELECT ON airbnb.vistaInformacionAlojamientos TO 'luisriv10'@'localhost';
GRANT SELECT ON airbnb.vistaInformacionReservas TO 'luisriv10'@'localhost';

-- Permisos para el anfitrión Anto (anto11)
GRANT INSERT, UPDATE, DELETE ON airbnb.alojamiento TO 'anto11'@'localhost';
GRANT EXECUTE ON PROCEDURE airbnb.InsertarReglaA TO 'anto11'@'localhost';
GRANT SELECT ON airbnb.vistaInformacionAlojamientos TO 'anto11'@'localhost';
GRANT SELECT ON airbnb.vistaInformacionReservas TO 'anto11'@'localhost';

-- Permisos para el cliente Anthony (anthonyc20)
GRANT SELECT ON airbnb.vistaInformacionAlojamientos TO 'anthonyc20'@'localhost';
GRANT SELECT ON airbnb.vistaInformacionReservas TO 'anthonyc20'@'localhost';

-- Permisos para el cliente Alvan (alvancon21)
GRANT SELECT ON airbnb.vistaInformacionAlojamientos TO 'alvancon21'@'localhost';
GRANT SELECT ON airbnb.vistaInformacionReservas TO 'alvancon21'@'localhost';

-- Permisos para el administrador
GRANT ALL PRIVILEGES ON airbnb.* TO 'admin'@'localhost';
FLUSH PRIVILEGES;
