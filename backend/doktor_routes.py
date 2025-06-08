# from flask import Blueprint, request, jsonify
# from config import get_db_connection

# doktor_bp = Blueprint('doktor_bp', __name__)

# @doktor_bp.route('/doctor_login', methods=['POST'])
# def doctor_login():
#     data = request.get_json()
#     kullanici_adi = data.get('username')
#     sifre = data.get('password')

#     conn = get_db_connection()
#     cur = conn.cursor()
#     cur.execute("""
#         SELECT doktor_id, ad, soyad FROM doktorlar
#         WHERE kullanici_adi = %s AND sifre = %s
#     """, (kullanici_adi, sifre))

#     doktor = cur.fetchone()
#     cur.close()
#     conn.close()

#     if doktor:
#         return jsonify({
#             "success": True,
#             "doktor_id": doktor[0],
#             "ad": doktor[1],
#             "soyad": doktor[2]
#         })
#     else:
#         return jsonify({"success": False, "message": "Hatalı kullanıcı adı veya şifre"}), 401
