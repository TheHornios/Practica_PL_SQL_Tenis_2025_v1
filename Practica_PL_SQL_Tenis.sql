/*
* Rodrigo Pascual Arnaiz rpa1004@alu.ubu.es
* Url git: https://github.com/TheHornios/Practica_PL_SQL_Tenis_2025_v1
*/

/* 2025_v1 */

drop table reservas;
drop table pistas;
drop sequence seq_pistas;

create table pistas (
	nro integer primary key
	);
	
create table reservas (
	pista integer references pistas(nro),
	fecha date,
	hora integer check (hora >= 0 and hora <= 23),
	socio varchar(20),
	primary key (pista, fecha, hora)
	);
	
create sequence seq_pistas;

insert into pistas values (seq_pistas.nextval);
insert into reservas 
	values (seq_pistas.currval, '20/03/2018', 14, 'Pepito');
insert into pistas values (seq_pistas.nextval);
insert into reservas 
	values (seq_pistas.currval, '24/03/2018', 18, 'Pepito');
insert into reservas 
	values (seq_pistas.currval, '21/03/2018', 14, 'Juan');
insert into pistas values (seq_pistas.nextval); 
insert into reservas 
	values (seq_pistas.currval, '22/03/2018', 13, 'Lola');
insert into reservas 
	values (seq_pistas.currval, '22/03/2018', 12, 'Pepito');

commit;

create or replace function anularReserva( 
	p_socio varchar,
	p_fecha date,
	p_hora integer, 
	p_pista integer ) 
return integer is

begin
	DELETE FROM reservas 
        WHERE
            trunc(fecha) = trunc(p_fecha) AND
            pista = p_pista AND
            hora = p_hora AND
            socio = p_socio;

	if sql%rowcount = 1 then
		commit;
		return 1;
	else
		rollback;
		return 0;
	end if;
end;
/

create or replace FUNCTION reservarPista(
        p_socio VARCHAR,
        p_fecha DATE,
        p_hora INTEGER
    ) 
RETURN INTEGER IS

    CURSOR vPistasLibres IS
        SELECT nro
        FROM pistas 
        WHERE nro NOT IN (
            SELECT pista
            FROM reservas
            WHERE 
                trunc(fecha) = trunc(p_fecha) AND
                hora = p_hora)
        order by nro;
            
    vPista INTEGER;

BEGIN
    OPEN vPistasLibres;
    FETCH vPistasLibres INTO vPista;

    IF vPistasLibres%NOTFOUND
    THEN
        CLOSE vPistasLibres;
        RETURN 0;
    END IF;

    -- Intentar insertar la reserva
    BEGIN
        INSERT INTO reservas VALUES (vPista, p_fecha, p_hora, p_socio);
        CLOSE vPistasLibres;
        COMMIT;
        RETURN 1;
    EXCEPTION
    WHEN OTHERS THEN
        -- Manejo de errores: cerrar cursor y hacer rollback
        IF vPistasLibres%ISOPEN THEN
            CLOSE vPistasLibres;
        END IF;
        ROLLBACK;
        RETURN -1;
    END;
END;
/

/*
SET SERVEROUTPUT ON
declare
 resultado integer;
begin
 
     resultado := reservarPista( 'Socio 1', CURRENT_DATE, 12 );
     if resultado=1 then
        dbms_output.put_line('Reserva 1: OK');
     else
        dbms_output.put_line('Reserva 1: MAL');
     end if;
     
     --Continua tu solo....
     
      
    resultado := anularreserva( 'Socio 1', CURRENT_DATE, 12, 1);
     if resultado=1 then
        dbms_output.put_line('Reserva 1 anulada: OK');
     else
        dbms_output.put_line('Reserva 1 anulada: MAL');
     end if;
  
     resultado := anularreserva( 'Socio 1', date '1920-1-1', 12, 1);
     --Continua tu solo....
  
end;
/
*/

/*  
1 ->  ¿Por qué en las comparacionesde fecha en Oracle conviene utilizar la función trunc?  

    En Oracle, los valores de tipo DATE incluyen fecha y hora, la comparación podría fallar si las horas son diferentes, 
    trunc(fecha) elimina la parte horaria y permite comparar solo el día.  
*/

/*  
2 ->  ¿Qué es sql%rowcount y cómo funciona?  

    sql%rowcount devuelve el número de filas afectadas por la última sentencia DML, por ejemplo en anularReserva se utiliza para saber si el DELETE afecto a una fila
    si se elimina una fila se confirma la tansaccion con un COMMIT y se devuelve 1, en el caso contrario se hace un ROLBACK
*/

/*  
3 ->  ¿Qué es una variable de tipo cursor?
    
    Un cusror es una estructura que permite recorrer filas de una consulta. 

  ->  ¿Qué variable de tipo cursor hay en la segunda función?

    En reservarPista, el cursor vPistasLibres obtiene las pistas disponibles para la fecha y hora dadas

  ->  ¿Qué efecto tienen las operaciones open, fetch y close?
  
    - open: Ejecuta la consulta y prepara los resultados  
    - fetch: Obtiene la siguiente fila disponible
    - close: Libera los recursos del cursor

  ->  ¿Qué valores toman las propiedades de cursor FOUND y NOTFOUND y en qué caso?

    - FOUND: TRUE si el FETCH obtuvo una fila, FALSE si no hay más datos
    - NOTFOUND: TRUE si no hay más filas disponibles, FALSE si aún hay datos 
*/

/*  
4 -> En la función anularReserva discute si da lo mismo sustituir el rollback por un commit y por qué

    No, si se usa COMMIT en lugar de ROLLBACK cuando no se elimina ninguna fila, la transacción se confirmaría aunque no se haya hecho ninguna modificación, usar COMMIT podría 
    dar la falsa impresión de que la eliminación tuvo éxito cuando no fue así
*/

/*  
5 -> En la función reservarPista investiga si la transacción se puede quedar abierta en algún caso

    Sí, si INSERT falla después del FETCH, la transacción puede quedar abierta, para evitarlo, se debe manejar excepciones y asegurar que el cursor siempre se cierre.
*/


/* PASO 2 - 1.1*/

/*
SET SERVEROUTPUT ON;

DECLARE
    resultado INTEGER;
BEGIN
    -- Intentamos hacer 3 reservas válidas
    resultado := reservarPista('Socio 1', CURRENT_DATE, 12);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Reserva 1: OK');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Reserva 1: FALLIDA');
    END IF;

    resultado := reservarPista('Socio 2', CURRENT_DATE, 12);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Reserva 2: OK');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Reserva 2: FALLIDA');
    END IF;

    resultado := reservarPista('Socio 3', CURRENT_DATE, 12);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Reserva 3: OK');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Reserva 3: FALLIDA');
    END IF;

    -- Intentamos una cuarta reserva, que debería fallar
    resultado := reservarPista('Socio 4', CURRENT_DATE, 12);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Reserva 4: ERROR (No debería haberse reservado)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Reserva 4: OK (No había hueco)');
    END IF;
    
END;
/
*/

/* PASO 2 - 1.2*/
/*
SET SERVEROUTPUT ON;

DECLARE
    resultado INTEGER;
BEGIN
    -- Anulamos una reserva existente
    resultado := anularReserva('Socio 1', CURRENT_DATE, 12, 1);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Anulación 1: OK (Reserva eliminada)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Anulación 1: FALLIDA (No se eliminó)');
    END IF;

    -- Intentamos anular una reserva inexistente
    resultado := anularReserva('Socio 1', DATE '1920-1-1', 12, 1);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Anulación 2: ERROR (No debería haberse eliminado)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Anulación 2: OK (Reserva no existía)');
    END IF;
    
END;
/
*/

/* PASO 2 - 2*/
/*SELECT * FROM reservas ORDER BY fecha, hora, pista;*/


/* PASO 3 - 1*/
GRANT DEBUG CONNECT SESSION TO hr;
GRANT DEBUG ANY PROCEDURE TO hr;


/* PASO 3 - 2*/

DECLARE
    resultado INTEGER;
BEGIN
    resultado := reservarPista('Socio 5', CURRENT_DATE, 15);
END;
/


/* PASO 4*/
CREATE OR REPLACE PROCEDURE TEST_FUNCIONES_TENIS 
IS
    resultado INTEGER;
BEGIN
    -- Intentamos hacer 3 reservas válidas
    resultado := reservarPista('Socio 1', CURRENT_DATE, 12);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Reserva 1: ERROR (No debería haberse reservado)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Reserva 1: OK (No había hueco)');
    END IF;

    resultado := reservarPista('Socio 2', CURRENT_DATE, 12);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Reserva 2: ERROR (No debería haberse reservado)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Reserva 2: OK (No había hueco)');
    END IF;

    resultado := reservarPista('Socio 3', CURRENT_DATE, 12);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Reserva 3: ERROR (No debería haberse reservado)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Reserva 3: OK (No había hueco)');
    END IF;
    
    -- Intentamos hacer una reserva inválida (sin hueco)
    resultado := reservarPista('Socio 4', CURRENT_DATE, 12);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Reserva 4: ERROR (No debería haberse reservado)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Reserva 4: OK (No había hueco)');
    END IF;

    -- Anulamos una reserva válida
    resultado := anularReserva('Socio 1', CURRENT_DATE, 12, 1);
    IF resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Anulación 1: OK (Reserva eliminada)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Anulación 1: FALLIDA (No se eliminó)');
    END IF;

    -- Intentamos anular una reserva inexistente
    resultado := anularReserva('Socio 1', DATE '1920-1-1', 12, 1);
    IF resultado = 2 THEN
        DBMS_OUTPUT.PUT_LINE('Anulación 1: OK (Reserva eliminada)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Anulación 1: FALLIDA (No se eliminó)');
    END IF;

    -- Consulta final para verificar resultados
    EXECUTE IMMEDIATE 'SELECT * FROM reservas ORDER BY fecha, hora, pista';
END;
/

EXEC TEST_FUNCIONES_TENIS;

BEGIN
    TEST_FUNCIONES_TENIS;
END;
/