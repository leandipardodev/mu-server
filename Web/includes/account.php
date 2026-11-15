<?php
require_once __DIR__ . '/db.php';

function account_get($conn, $id) {
    $st = db_query($conn, "SELECT * FROM MEMB_INFO WHERE memb___id = ?", [$id]);
    return db_fetch_one($st);
}

function account_characters($conn, $accountId) {
    // Intentar obtener lista desde AccountCharacter (GameID1..10 o variantes)
    $names = [];
    try {
        $st = db_query($conn, "SELECT * FROM AccountCharacter WHERE Id = ?", [$accountId]);
        $row = db_fetch_one($st);
        if ($row) {
            // recolectar campos tipo GameID*
            foreach ($row as $k => $v) {
                if (stripos($k, 'GameID') === 0 && is_string($v)) {
                    $v = trim($v);
                    if ($v !== '') $names[] = $v;
                }
            }
            $names = array_values(array_unique($names));
        }
    } catch (Exception $e) {
        // fallback: Character.AccountID
    }
    if (!$names) {
        try {
            $st = db_query($conn, "SELECT Name FROM Character WHERE AccountID = ?", [$accountId]);
            foreach (db_fetch_all($st) as $r) {
                if (!empty($r['Name'])) $names[] = trim($r['Name']);
            }
        } catch (Exception $e) {}
    }
    if (!$names) return [];

    // Obtener datos de personajes con columnas flexibles
    $chars = [];
    foreach ($names as $name) {
        try {
            $st = db_query($conn, "SELECT TOP 1 * FROM Character WHERE Name = ?", [$name]);
            $c = db_fetch_one($st);
            if ($c) $chars[] = $c;
        } catch (Exception $e) {}
    }
    return $chars;
}

function char_class_name($c) {
    $map = [0=>'Dark Wizard',1=>'Soul Master',2=>'Grand Master',16=>'Dark Knight',17=>'Blade Knight',18=>'Blade Master',32=>'Fairy Elf',33=>'Muse Elf',34=>'High Elf',48=>'Magic Gladiator',50=>'Duel Master',64=>'Dark Lord',66=>'Lord Emperor'];
    $ci = (int)$c;
    return $map[$ci] ?? ('Clase ' . $ci);
}

function char_field($c, $keys, $default = 0) {
    foreach ($keys as $k) {
        if (array_key_exists($k, $c) && $c[$k] !== null && $c[$k] !== '') return $c[$k];
    }
    // case-insensitive
    $lower = [];
    foreach ($c as $k=>$v) $lower[strtolower($k)] = $v;
    foreach ($keys as $k) {
        $lk = strtolower($k);
        if (array_key_exists($lk, $lower) && $lower[$lk] !== null && $lower[$lk] !== '') return $lower[$lk];
    }
    return $default;
}

function char_belongs_to($conn, $accountId, $charName) {
    $chars = account_characters($conn, $accountId);
    foreach ($chars as $c) {
        $n = trim((string)char_field($c, ['Name'], ''));
        if (strcasecmp($n, $charName) === 0) return $c;
    }
    return null;
}
?>