/*5.1 */
CREATE OR REPLACE PROCEDURE pAnularReserva(
    p_socio VARCHAR,
    p_fecha DATE,
    p_hora INTEGER,
    p_pista INTEGER
) IS
BEGIN
    DELETE FROM reservas
    WHERE trunc(fecha) = trunc(p_fecha)
      AND pista = p_pista
      AND hora = p_hora
      AND socio = p_socio;

    IF SQL%ROWCOUNT = 0 THEN
        raise_application_error(-20000, 'Reserva inexistente');
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE; -- Re-lanza la excepción original
END;
/

CREATE OR REPLACE PROCEDURE pReservarPista(
    p_socio VARCHAR,
    p_fecha DATE,
    p_hora INTEGER
) IS
    CURSOR vPistasLibres IS
        SELECT nro
        FROM pistas
        WHERE nro NOT IN (
            SELECT pista
            FROM reservas
            WHERE trunc(fecha) = trunc(p_fecha)
              AND hora = p_hora
        )
        ORDER BY nro;

    vPista INTEGER;
BEGIN
    OPEN vPistasLibres;
    FETCH vPistasLibres INTO vPista;

    IF vPistasLibres%NOTFOUND THEN
        CLOSE vPistasLibres;
        raise_application_error(-20001, 'No quedan pistas libres en esa fecha y hora');
    END IF;

    INSERT INTO reservas VALUES (vPista, p_fecha, p_hora, p_socio);
    CLOSE vPistasLibres;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        IF vPistasLibres%ISOPEN THEN
            CLOSE vPistasLibres;
        END IF;
        ROLLBACK;
        RAISE;
END;
/