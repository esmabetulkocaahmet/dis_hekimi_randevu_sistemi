from flask import Flask, request, jsonify, send_from_directory
import psycopg2
from psycopg2.extras import RealDictCursor
from flask_cors import CORS
import bcrypt
import os
import base64
import traceback
import uuid
from werkzeug.utils import secure_filename
from datetime import datetime, time, timedelta
from datetime import datetime, date


app = Flask(__name__)
CORS(app)

# Veritabanı bağlantı fonksiyonu
def get_db_connection():
    return psycopg2.connect(
        dbname='dis_randevu_sistemi',
        user='postgres',
        password='123456',
        host='localhost',
        port='5432'
    )

BASE_UPLOAD_DIR = os.path.join(os.getcwd(), 'uploads')
app.config['UPLOAD_FOLDER'] = BASE_UPLOAD_DIR

# Doktor dizinleri
DOCTOR_DIR = os.path.join(BASE_UPLOAD_DIR, 'doctor')
DIPLOMA_DIR = os.path.join(DOCTOR_DIR, 'diplomalar')
BELGE_DIR = os.path.join(DOCTOR_DIR, 'belgeler')

# Hasta dizinleri
HASTA_DIR = os.path.join(BASE_UPLOAD_DIR, 'hasta')
RAPOR_DIR = os.path.join(HASTA_DIR, 'raporlar')
RONTGEN_DIR = os.path.join(HASTA_DIR, 'rontgenler')

# Dizinlerin oluşturulması
os.makedirs(DIPLOMA_DIR, exist_ok=True)
os.makedirs(BELGE_DIR, exist_ok=True)
os.makedirs(RAPOR_DIR, exist_ok=True)
os.makedirs(RONTGEN_DIR, exist_ok=True)


def upload_base64_file(base64_str, save_dir, prefix):
    if not base64_str:
        return None

    os.makedirs(save_dir, exist_ok=True)
    filename = f"{prefix}_{uuid.uuid4().hex}.pdf"
    filepath = os.path.join(save_dir, filename)

    with open(filepath, "wb") as f:
        f.write(base64.b64decode(base64_str))

    return filepath


#-------------------------------------DOCTOR------------------------------------------------------------------
# Doktor Kayıt
@app.route('/doctor_register', methods=['POST'])
def doctor_register():
    data = request.json

    try:
        # Adres bilgilerini al
        il = data.get('il')
        ilce = data.get('ilce')
        tamadres = data.get('tamadres')



        if not (il and ilce and tamadres):
            return jsonify({"error": "Adres bilgileri (il, ilce, tamadres) zorunludur."}), 400
        

        conn = get_db_connection()
        cursor = conn.cursor()

        # Adresi adresler tablosuna ekle
        insert_adres_query = """
            INSERT INTO adres (il, ilce, tamadres)
            VALUES (%s, %s, %s)
            RETURNING adres_id
        """
        cursor.execute(insert_adres_query, (il, ilce, tamadres))
        adres_id = cursor.fetchone()[0]

        # Dosyaları base64'ten kaydet
        diploma_path = upload_base64_file(data.get('diploma_belgesi'), DIPLOMA_DIR, 'diploma')
        belge_path = upload_base64_file(data.get('isyeri_belgesi'), BELGE_DIR, 'belge')

        # Şifre hashle
        hashed_password = bcrypt.hashpw(data.get('sifre').encode('utf-8'), bcrypt.gensalt())

        insert_doktor_query = """
            INSERT INTO doktorlar (
                ad, soyad, tc_kimlik_no, brans, dogum_tarihi, cinsiyet,
                kullanici_adi, sifre, adres_id,
                diploma_belgesi, isyeri_belgesi
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """

        values = (
            data.get('ad'),
            data.get('soyad'),
            data.get('tc_kimlik_no'),
            data.get('brans'),
            data.get('dogum_tarihi'),
            data.get('cinsiyet'),
            data.get('kullanici_adi'),
            hashed_password.decode('utf-8'),
            adres_id,
            diploma_path,
            belge_path
        )

        cursor.execute(insert_doktor_query, values)
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "Doktor başarıyla kaydedildi"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# Doktor Giriş
@app.route('/doctor_login', methods=['POST'])
def doctor_login():
    data = request.json
    kullanici_adi = data.get('kullanici_adi')
    girilen_sifre = data.get('sifre')

    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("SELECT * FROM doktorlar WHERE kullanici_adi = %s", (kullanici_adi,))
        doktor = cursor.fetchone()

        cursor.close()
        conn.close()

        if doktor and bcrypt.checkpw(girilen_sifre.encode('utf-8'), doktor['sifre'].encode('utf-8')):
            return jsonify({
                "message": "Giriş başarılı",
                "doktor_id": doktor['doktor_id'],
                "ad": doktor['ad'],
                "soyad": doktor['soyad']
            }), 200
        else:
            return jsonify({"error": "Kullanıcı adı veya şifre hatalı"}), 401

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/doctor_profile/<int:doktor_id>', methods=['GET'])
def get_doctor_profile(doktor_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT ad, soyad, tc_kimlik_no, brans, cinsiyet, dogum_tarihi,
                   diploma_belgesi, isyeri_belgesi, randevu_araligi
            FROM doktorlar
            WHERE doktor_id = %s
        """, (doktor_id,))
        doktor = cursor.fetchone()

        cursor.close()
        conn.close()

        if doktor:
            # Belgeleri base64 formatına çevir
            for belge_field in ['diploma_belgesi', 'isyeri_belgesi']:
                path = doktor.get(belge_field)
                if path and os.path.exists(path):
                    with open(path, 'rb') as f:
                        doktor[belge_field] = base64.b64encode(f.read()).decode('utf-8')
                else:
                    doktor[belge_field] = None

            return jsonify(doktor), 200
        else:
            return jsonify({'error': 'Doktor bulunamadı'}), 404

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/appointments', methods=['GET'])
def get_appointments():
    doktor_id = request.args.get('doktor_id')
    tarih = request.args.get('tarih')  # YYYY-MM-DD formatında

    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    cursor.execute("""
        SELECT r.hasta_id, hastalar.ad AS hasta_adi, hastalar.soyad AS hasta_soyadi, hastalar.cinsiyet, r.saat
        FROM randevular r
        JOIN hastalar ON hastalar.hasta_id = r.hasta_id
        WHERE r.doktor_id = %s AND r.tarih = %s
        ORDER BY r.saat
    """, (doktor_id, tarih))

    randevular = cursor.fetchall()
    cursor.close()
    conn.close()

    # Saatleri string'e çevir
    for r in randevular:
        r["saat"] = r["saat"].strftime("%H:%M")

    return jsonify(randevular)


#Profil düzenle
@app.route('/doctor_update/<int:doktor_id>', methods=['PUT'])
def update_doctor_profile(doktor_id):
    data = request.json
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Şifre güncelleme
        if data.get('sifre'):
            hashed_password = bcrypt.hashpw(data['sifre'].encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            cursor.execute("UPDATE doktorlar SET sifre = %s WHERE doktor_id = %s", (hashed_password, doktor_id))

        # Temel alanları güncelleme
        update_fields = ['soyad', 'brans', 'kullanici_adi']
        for field in update_fields:
            if data.get(field):
                cursor.execute(f"UPDATE doktorlar SET {field} = %s WHERE doktor_id = %s", (data[field], doktor_id))

        # Belge güncelleme
        if data.get('diploma_belgesi'):
            diploma_path = upload_base64_file(data['diploma_belgesi'], DIPLOMA_DIR, 'diploma')
            if diploma_path:
                cursor.execute("UPDATE doktorlar SET diploma_belgesi = %s WHERE doktor_id = %s", (diploma_path, doktor_id))

        if data.get('isyeri_belgesi'):
            belge_path = upload_base64_file(data['isyeri_belgesi'], BELGE_DIR, 'belge')
            if belge_path:
                cursor.execute("UPDATE doktorlar SET isyeri_belgesi = %s WHERE doktor_id = %s", (belge_path, doktor_id))

        # Adres güncelleme
        adres = data.get('adres')
        if adres:
            il = adres.get('il')
            ilce = adres.get('ilce')
            tamadres = adres.get('tamadres')

            if il or ilce or tamadres:
                # Doktorun adres_id'sini al
                cursor.execute("SELECT adres_id FROM doktorlar WHERE doktor_id = %s", (doktor_id,))
                adres_result = cursor.fetchone()

                if adres_result and adres_result[0]:
                    adres_id = adres_result[0]
                    if il:
                        cursor.execute("UPDATE adres SET il = %s WHERE adres_id = %s", (il, adres_id))
                    if ilce:
                        cursor.execute("UPDATE adres SET ilce = %s WHERE adres_id = %s", (ilce, adres_id))
                    if tamadres:
                        cursor.execute("UPDATE adres SET tamadres = %s WHERE adres_id = %s", (tamadres, adres_id))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "Profil başarıyla güncellendi"}), 200

    except Exception as e:
        traceback.print_exc() 
        return jsonify({"error": str(e)}), 500
    

# 1. Doktor ayarlarını getir
@app.route('/api/doctor/settings/<int:doctor_id>', methods=['GET'])
def doktor_ayarlarini_getir(doctor_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT baslangic_saat, baslangic_dakika, bitis_saat, bitis_dakika, randevu_aralik
        FROM doktor_ayarlar
        WHERE doktor_id = %s
    """, (doctor_id,))
    sonuc = cursor.fetchone()
    cursor.close()
    conn.close()

    if sonuc:
        return jsonify({
            "start_hour": sonuc[0],
            "start_minute": sonuc[1],
            "end_hour": sonuc[2],
            "end_minute": sonuc[3],
            "interval_minutes": sonuc[4]
        })
    return jsonify({}), 404


# 2. Doktor ayarlarını kaydet
@app.route('/api/doctor/settings', methods=['POST'])
def doktor_ayarlarini_kaydet():
    veri = request.get_json()
    doctor_id = veri['doctor_id']
    start_hour = veri['start_hour']
    start_minute = veri['start_minute']
    end_hour = veri['end_hour']
    end_minute = veri['end_minute']
    interval_minutes = veri['interval_minutes']

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT doktor_id FROM doktor_ayarlar WHERE doktor_id = %s", (doctor_id,))
    var_mi = cursor.fetchone()

    if var_mi:
        cursor.execute("""
            UPDATE doktor_ayarlar SET
                baslangic_saat = %s,
                baslangic_dakika = %s,
                bitis_saat = %s,
                bitis_dakika = %s,
                randevu_aralik = %s
            WHERE doktor_id = %s
        """, (start_hour, start_minute, end_hour, end_minute, interval_minutes, doctor_id))
    else:
        cursor.execute("""
            INSERT INTO doktor_ayarlar 
                (doktor_id, baslangic_saat, baslangic_dakika, bitis_saat, bitis_dakika, randevu_aralik)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (doctor_id, start_hour, start_minute, end_hour, end_minute, interval_minutes))

    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({"message": "Ayarlar kaydedildi"})


# 3. Belirli gün için kapalı saatleri getir
@app.route('/api/doctor/closed_slots/<int:doctor_id>', methods=['GET'])
def kapali_saatleri_getir(doctor_id):
    tarih_str = request.args.get('date')  # Flutter "yyyy-MM-dd" formatında gönderiyor

    conn = get_db_connection()
    cursor = conn.cursor()

    # Doktorun kapattığı saatler
    cursor.execute("""
        SELECT saat FROM kapali_randevu_saatleri
        WHERE doktor_id = %s AND tarih = %s
    """, (doctor_id, tarih_str))
    kapali_saatler = [s[0].strftime("%H:%M") for s in cursor.fetchall()]

    # Hastalar tarafından alınmış randevular
    cursor.execute("""
        SELECT saat FROM randevular
        WHERE doktor_id = %s AND tarih = %s
    """, (doctor_id, tarih_str))
    alinmis_saatler = [s[0].strftime("%H:%M") for s in cursor.fetchall()]

    cursor.close()
    conn.close()

    # Tek listede birleştir ve tekrarsız hale getir
    tum_kapali_saatler = list(set(kapali_saatler + alinmis_saatler))

    return jsonify(tum_kapali_saatler)


# 4. Randevu saatini kapatma/açma
@app.route('/api/doctor/closed_slot', methods=['POST'])
def randevu_saati_guncelle():
    veri = request.get_json()
    doctor_id = veri['doctor_id']
    tarih = veri['date']  # Flutter: "date"
    saat = veri['time']   # Flutter: "time"
    kapali = veri['closed']  # Flutter: "closed"

    tarih_obj = datetime.strptime(tarih, "%Y-%m-%d").date()
    saat_obj = datetime.strptime(saat, "%H:%M").time()

    conn = get_db_connection()
    cursor = conn.cursor()
    if kapali:
        cursor.execute("""
            INSERT INTO kapali_randevu_saatleri (doktor_id, tarih, saat)
            VALUES (%s, %s, %s)
            ON CONFLICT DO NOTHING
        """, (doctor_id, tarih_obj, saat_obj))
    else:
        cursor.execute("""
            DELETE FROM kapali_randevu_saatleri
            WHERE doktor_id = %s AND tarih = %s AND saat = %s
        """, (doctor_id, tarih_obj, saat_obj))

    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({"message": "Saat güncellendi"})


@app.route('/available_slots/<int:doktor_id>/<string:tarih>', methods=['GET'])
def get_available_slots(doktor_id, tarih):
    conn = get_db_connection()
    cursor = conn.cursor()

    # Doktorun ayarlarını al
    cursor.execute("""
        SELECT baslangic_saat, baslangic_dakika, bitis_saat, bitis_dakika, randevu_aralik
        FROM doktor_ayarlar
        WHERE doktor_id = %s
    """, (doktor_id,))
    ayar = cursor.fetchone()

    if not ayar:
        return jsonify({'error': 'Doktor ayarı bulunamadı'}), 404

    # Başlangıç ve bitiş zamanını dakikaya çevir
    baslangic = int(ayar[0]) * 60 + int(ayar[1])
    bitis = int(ayar[2]) * 60 + int(ayar[3])
    aralik = int(ayar[4])

    # Mevcut randevuları al
    cursor.execute("""
        SELECT saat FROM randevular
        WHERE doktor_id = %s AND tarih = %s
    """, (doktor_id, tarih))
    dolu_saatler = [r[0].strftime('%H:%M') for r in cursor.fetchall()]

    # Tüm olası saatleri oluştur
    mevcut_saatler = []
    for dakika in range(baslangic, bitis, aralik):
        saat_str = f"{dakika // 60:02d}:{dakika % 60:02d}"
        mevcut_saatler.append({
            'saat': saat_str,
            'durum': 'dolu' if saat_str in dolu_saatler else 'bos'
        })

    return jsonify(mevcut_saatler)

# /api/doctor/booked_slots/<doctor_id>?date=...
@app.route('/api/doctor/booked_slots/<int:doctor_id>', methods=['GET'])
def alinmis_randevu_saatleri(doctor_id):
    tarih_str = request.args.get('date')  # 'YYYY-MM-DD'

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT saat FROM randevular
        WHERE doktor_id = %s AND tarih = %s
    """, (doctor_id, tarih_str))
    sonuc = cursor.fetchall()
    cursor.close()
    conn.close()

    return jsonify([s[0].strftime("%H:%M") for s in sonuc])



#-----------------------------HASTA---------------------------------------------------

# Hasta Kayıt
@app.route('/patient_register', methods=['POST'])
def patient_register():
    data = request.json
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Yeni fonksiyonla base64 dosyaları kaydet
        rapor_path = upload_base64_file(data.get('rapor_belgesi'), RAPOR_DIR, 'rapor')
        rontgen_path = upload_base64_file(data.get('rontgen_belgesi'), RONTGEN_DIR, 'rontgen')

        hashed_password = bcrypt.hashpw(data.get('sifre').encode('utf-8'), bcrypt.gensalt())

        insert_query = """
            INSERT INTO hastalar (
                ad, soyad, tc_kimlik_no, dogum_tarihi, cinsiyet,
                kullanici_adi, sifre, adres,
                ameliyat_raporu, rontgen
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """

        values = (
            data.get('ad'),
            data.get('soyad'),
            data.get('tc_kimlik_no'),
            data.get('dogum_tarihi'),
            data.get('cinsiyet'),
            data.get('kullanici_adi'),
            hashed_password.decode('utf-8'),
            data.get('adres'),
            rapor_path,
            rontgen_path
        )

        cursor.execute(insert_query, values)
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "Hasta başarıyla kaydedildi"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Hasta giriş endpoint'i
@app.route('/patient_login', methods=['POST'])
def patient_login():
    data = request.get_json() or {}
    tc = data.get('tc_kimlik_no')
    sifre = data.get('sifre')

    if not tc or not sifre:
        return jsonify({'message': 'TC Kimlik No ve şifre gerekli'}), 400


    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """
            SELECT hasta_id, ad, soyad, sifre
            FROM hastalar
            WHERE tc_kimlik_no = %s
            """,
            (tc,)
        )
        hasta = cur.fetchone()
        if hasta is None:
            return jsonify({'message': 'Kullanıcı bulunamadı'}), 404
        if hasta and bcrypt.checkpw(sifre.encode('utf-8'), hasta['sifre'].encode('utf-8')):
            return jsonify({
                "message": "Giriş başarılı",
                'hasta_id': hasta['hasta_id'],
                'ad': hasta['ad'],
                'soyad': hasta['soyad']
            }), 200

        else:
            return jsonify({"error": "TC kimlik no veya şifre hatalı"}), 401
        

    finally:
        cur.close()
        conn.close()


@app.route('/get_patient/<int:hasta_id>', methods=['GET'])
def get_patient(hasta_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT ad FROM hastalar WHERE hasta_id = %s", (hasta_id,))
        hasta = cursor.fetchone()
        cursor.close()
        conn.close()

        if hasta:
            return jsonify({'ad': hasta[0]}), 200
        else:
            return jsonify({'error': 'Hasta bulunamadı'}), 404

    except Exception as e:
        return jsonify({'error': str(e)}), 500

    
@app.route('/api/doctors', methods=['GET'])
def get_doctors_by_city_district():
    city = request.args.get('city')
    district = request.args.get('district')

    if not city or not district:
        return jsonify({'error': 'Şehir ve ilçe gereklidir'}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    query = """
        SELECT doktorlar.doktor_id, doktorlar.ad, doktorlar.soyad
        FROM doktorlar 
        JOIN adres  ON doktorlar.adres_id = adres.adres_id
        WHERE adres.il = %s AND adres.ilce = %s
    """
    cursor.execute(query, (city, district))
    rows = cursor.fetchall()

    # Kolon isimlerini al
    columns = [desc[0] for desc in cursor.description]

    # Her satırı sözlüğe çevir
    doctors = [dict(zip(columns, row)) for row in rows]

    cursor.close()
    conn.close()

    return jsonify(doctors)  # Liste formatında JSON döndürülür


@app.route('/api/doctor/available_slots/<int:doktor_id>', methods=['GET'])
def doktor_musait_saatler(doktor_id):
    tarih_str = request.args.get('date')  # Örn: 2025-05-23
    if not tarih_str:
        return jsonify({"error": "Tarih belirtilmedi"}), 400

    tarih = datetime.strptime(tarih_str, "%Y-%m-%d").date()

    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. Doktorun saat ayarlarını al
    cursor.execute("""
        SELECT baslangic_saat, baslangic_dakika, bitis_saat, bitis_dakika, randevu_aralik
        FROM doktor_ayarlar WHERE doktor_id = %s
    """, (doktor_id,))
    ayarlar = cursor.fetchone()
    if not ayarlar:
        cursor.close()
        conn.close()
        return jsonify({"error": "Doktor ayarları bulunamadı"}), 404

    start_hour, start_minute, end_hour, end_minute, interval_minutes = ayarlar
    start_time = time(start_hour, start_minute)
    end_time = time(end_hour, end_minute)

    # 2. Kapalı saatleri al
    cursor.execute("""
        SELECT saat FROM kapali_randevu_saatleri
        WHERE doktor_id = %s AND tarih = %s
    """, (doktor_id, tarih))
    kapali_saatler = {r[0].strftime("%H:%M") for r in cursor.fetchall()}

    # 3. Dolu (alınmış) saatleri al
    cursor.execute("""
        SELECT saat FROM randevular
        WHERE doktor_id = %s AND tarih = %s
    """, (doktor_id, tarih))
    dolu_saatler = {r[0].strftime("%H:%M") for r in cursor.fetchall()}

    cursor.close()
    conn.close()

    # 4. Tüm saat aralıklarını oluştur
    saat_listesi = []
    simdiki_zaman = datetime.combine(tarih, start_time)
    bitis_zamani = datetime.combine(tarih, end_time)
    while simdiki_zaman <= bitis_zamani:
        saat_str = simdiki_zaman.strftime("%H:%M")
        durum = "bos"
        if saat_str in kapali_saatler:
            durum = "kapali"
        elif saat_str in dolu_saatler:
            durum = "dolu"
        saat_listesi.append({
            "time": saat_str,
            "status": durum
        })
        simdiki_zaman += timedelta(minutes=interval_minutes)

    return jsonify(saat_listesi)


@app.route('/api/appointments/available/<int:doktor_id>', methods=['GET'])
def uygun_randevu_saatleri(doktor_id):
    tarih_str = request.args.get('tarih')  # YYYY-MM-DD
    tarih = datetime.strptime(tarih_str, "%Y-%m-%d").date()

    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. Doktor ayarlarını al
    cursor.execute("""
        SELECT baslangic_saat, baslangic_dakika, bitis_saat, bitis_dakika, randevu_aralik
        FROM doktor_ayarlar WHERE doktor_id = %s
    """, (doktor_id,))
    ayarlar = cursor.fetchone()
    if not ayarlar:
        return jsonify({"error": "Doktor ayarları bulunamadı"}), 404

    start = time(ayarlar[0], ayarlar[1])
    end = time(ayarlar[2], ayarlar[3])
    interval = ayarlar[4]

    # 2. Saat dilimlerini oluştur
    slots = []
    current = datetime.combine(tarih, start)
    end_dt = datetime.combine(tarih, end)
    while current <= end_dt:
        slots.append(current.time().strftime("%H:%M"))
        current += timedelta(minutes=interval)

    # 3. O gün alınan randevuları çek
    cursor.execute("""
        SELECT saat FROM randevular
        WHERE doktor_id = %s AND tarih = %s
    """, (doktor_id, tarih))
    dolu_saatler = [s[0].strftime("%H:%M") for s in cursor.fetchall()]

    # 4. Kapalı saatleri çek
    cursor.execute("""
        SELECT saat FROM kapali_randevu_saatleri
        WHERE doktor_id = %s AND tarih = %s
    """, (doktor_id, tarih))
    kapali_saatler = [s[0].strftime("%H:%M") for s in cursor.fetchall()]

    # 5. Hepsini birleştir
    sonuc = []
    for s in slots:
        if s in dolu_saatler:
            durum = "dolu"
        elif s in kapali_saatler:
            durum = "kapali"
        else:
            durum = "bos"
        sonuc.append({"saat": s, "durum": durum})

    cursor.close()
    conn.close()
    return jsonify(sonuc)

@app.route('/api/appointments/create', methods=['POST'])
def randevu_olustur():
    veri = request.get_json()
    doktor_id = veri['doktor_id']
    hasta_id = veri['hasta_id']
    tarih = datetime.strptime(veri['tarih'], "%Y-%m-%d").date()
    saat = datetime.strptime(veri['saat'], "%H:%M").time()

    conn = get_db_connection()
    cursor = conn.cursor()

    # Aynı saatte dolu mu?
    cursor.execute("""
        SELECT 1 FROM randevular
        WHERE doktor_id = %s AND tarih = %s AND saat = %s
    """, (doktor_id, tarih, saat))
    if cursor.fetchone():
        cursor.close()
        conn.close()
        return jsonify({"error": "Bu saat zaten dolu"}), 400

    # Kapalı mı?
    cursor.execute("""
        SELECT 1 FROM kapali_randevu_saatleri
        WHERE doktor_id = %s AND tarih = %s AND saat = %s
    """, (doktor_id, tarih, saat))
    if cursor.fetchone():
        cursor.close()
        conn.close()
        return jsonify({"error": "Bu saat kapalı"}), 400

    # Randevuyu kaydet
    cursor.execute("""
        INSERT INTO randevular (doktor_id, hasta_id, tarih, saat)
        VALUES (%s, %s, %s, %s)
    """, (doktor_id, hasta_id, tarih, saat))

    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({"message": "Randevu başarıyla oluşturuldu"})


@app.route('/next_appointment/<int:hasta_id>', methods=['GET'])
def next_appointment(hasta_id):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    # Bugünün tarihi, saat olmadan (YYYY-MM-DD)
    bugun = datetime.now().date()

    cursor.execute("""
        SELECT r.randevu_id, r.tarih, r.saat, d.ad AS doktor_adi, d.soyad AS doktor_soyad
        FROM randevular r
        JOIN doktorlar d ON d.doktor_id = r.doktor_id
        WHERE r.hasta_id = %s
          AND r.tarih >= %s
        ORDER BY r.tarih, r.saat
        LIMIT 1
    """, (hasta_id, bugun))

    randevu = cursor.fetchone()
    cursor.close()
    conn.close()

    if randevu is None:
        return jsonify({}), 404  # Randevu bulunamadı

    # Saat alanını string formatına çevir
    saat = randevu.get('saat')
    if isinstance(saat, time):
        saat_str = saat.strftime("%H:%M")
    else:
        saat_str = str(saat)

    return jsonify({
        'randevu_id': randevu['randevu_id'],
        'tarih': randevu['tarih'].strftime('%Y-%m-%d'),
        'saat': saat_str,
        'doktor_adi': f"{randevu['doktor_adi']} {randevu['doktor_soyad']}"
    })





@app.route('/patient_profile/<int:hasta_id>', methods=['GET'])
def get_patient_profile(hasta_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT ad, soyad, tc_kimlik_no, cinsiyet, dogum_tarihi, ameliyat_raporu, rontgen
            FROM hastalar
            WHERE hasta_id = %s
        """, (hasta_id,))
        hasta = cursor.fetchone()

        cursor.close()
        conn.close()
        
        if hasta:
            # dogum_tarihi varsa string olarak formatla
            if 'dogum_tarihi' in hasta and isinstance(hasta['dogum_tarihi'], (datetime, date)):
                hasta['dogum_tarihi'] = hasta['dogum_tarihi'].strftime("%Y-%m-%d")

            # Belgeleri base64 formatına çevir
            for belge_field in ['ameliyat_raporu', 'rontgen']:
                path = hasta.get(belge_field)
                if path and os.path.exists(path):
                    with open(path, 'rb') as f:
                        hasta[belge_field] = base64.b64encode(f.read()).decode('utf-8')
                else:
                    hasta[belge_field] = None

            return jsonify(hasta), 200
        else:
            return jsonify({'error': 'Hasta bulunamadı'}), 404

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/update_patient_profile', methods=['POST'])
def update_patient_profile():
    data = request.get_json()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        if 'hasta_id' not in data:
            return jsonify({'success': False, 'message': 'Hasta ID eksik'}), 400

        hasta_id = data['hasta_id']
        updated_fields = []
        values = []

        updated_fields = ['soyad', 'kullanici_adi']
        for field in updated_fields:
            if data.get(field):
                cursor.execute(f"UPDATE hastalar SET {field} = %s WHERE hasta_id = %s", (data[field], hasta_id))

        if data.get('sifre'):
            hashed_password = bcrypt.hashpw(data['sifre'].encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            cursor.execute("UPDATE hastalar SET sifre = %s WHERE hasta_id = %s", (hashed_password, hasta_id))

        # Belge güncelleme
        if data.get('ameliyat_raporu'):
            rapor_path = upload_base64_file(data['ameliyat_raporu'], RAPOR_DIR, 'raporlar')
            if rapor_path:
                cursor.execute("UPDATE hastalar SET ameliyat_raporu = %s WHERE hasta_id = %s", (rapor_path, hasta_id))

        if data.get('rontgen'):
            rontgen_path = upload_base64_file(data['rontgen'], RONTGEN_DIR, 'rontgenler')
            if rontgen_path:
                cursor.execute("UPDATE hastalar SET rontgen = %s WHERE hasta_id = %s", (rontgen_path, hasta_id))           


        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'success': True, 'message': 'Profil başarıyla güncellendi'})
    
    except Exception as e:
        return jsonify({'success': False, 'message': f'Veritabanı hatası: {str(e)}'}), 500
    

@app.route("/api/appointments/hasta", methods=["GET"])
def hasta_randevulari():
    hasta_id = request.args.get("hasta_id")

    if not hasta_id:
        return jsonify({"error": "Hasta ID gerekli"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT r.randevu_id, r.tarih, r.saat, d.ad, d.soyad
        FROM randevular r
        JOIN doktorlar d ON r.doktor_id = d.doktor_id
        WHERE r.hasta_id = %s
        ORDER BY r.tarih DESC, r.saat DESC
    """, (hasta_id,))

    randevular = cursor.fetchall()
    sonuc = []

    now = datetime.now()

    for r in randevular:
        randevu_tarihi = r[1]
        randevu_saati = r[2]

        # timezone varsa sıfırla
        if hasattr(randevu_tarihi, 'tzinfo') and randevu_tarihi.tzinfo is not None:
            randevu_tarihi = randevu_tarihi.replace(tzinfo=None)
        if hasattr(randevu_saati, 'tzinfo') and randevu_saati.tzinfo is not None:
            randevu_saati = randevu_saati.replace(tzinfo=None)

        randevu_datetime = datetime.combine(randevu_tarihi, randevu_saati)
        now_naive = now.replace(tzinfo=None)

        durum = "geçmiş" if randevu_datetime < now_naive else "gelecek"

        doktor_adi = f"{r[3]} {r[4]}"

        sonuc.append({
            "randevu_id": r[0],
            "doktor_adi": doktor_adi,
            "tarih": randevu_tarihi.strftime("%Y-%m-%d"),
            "saat": randevu_saati.strftime("%H:%M"),
            "durum": durum
        })

    cursor.close()
    conn.close()

    return jsonify(sonuc)


@app.route('/api/appointments/delete/<int:randevu_id>', methods=['DELETE'])
def randevu_sil(randevu_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM randevular WHERE randevu_id = %s", (randevu_id,))
    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({"message": "Randevu silindi"}), 200


@app.route('/api/appointments/future/<int:hasta_id>', methods=['GET'])
def get_all_future_appointments(hasta_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT r.randevu_id, r.tarih, r.saat, d.ad AS d_adi, d.soyad AS doktor_adi
            FROM randevular r
            JOIN doktorlar d ON r.doktor_id = d.doktor_id
            WHERE r.hasta_id = %s
              AND (
                r.tarih > CURRENT_DATE
                OR (r.tarih = CURRENT_DATE AND r.saat::time > CURRENT_TIME)
              )
            ORDER BY r.tarih, r.saat::time
        """, (hasta_id,))

        rows = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]

        appointments = []
        for row in rows:
            appointment = dict(zip(columns, row))
            appointment['tarih'] = appointment['tarih'].isoformat()
            appointment['saat'] = appointment['saat'].strftime('%H:%M')
            appointments.append(appointment)

        cursor.close()
        conn.close()

        return jsonify(appointments), 200

    except Exception as e:
        print("Hata:", e)
        return jsonify({'error': 'Veritabanı hatası'}), 500


if __name__ == '__main__':
    @app.route('/')
    def home():
       return "Randevu Sistemi API çalışıyor"

    app.run(host='0.0.0.0', port=5000, debug=True)