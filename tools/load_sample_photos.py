"""Uploads the local test photos in sample-photos/ to the LOCAL Supabase stack
and links them to the sample listings. Re-run after `supabase db reset`.

    python tools/load_sample_photos.py

Each photo is re-encoded as JPEG (EXIF/GPS metadata stripped, so a host's
location never leaks), stored full size (max 1600 px) plus a 480 px thumbnail,
under {owner_id}/{property_id}/ in the property-images bucket.
Never point this at a hosted project: it uses the local service-role key.
"""
import io
import os
import subprocess
import sys
import urllib.request
import uuid

from PIL import Image, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'sample-photos')
OWNER = '00000000-0000-4000-a000-000000000002'
# property id -> photo numbers in display order (first = cover). Photo 20 is
# left out: it duplicates photo 4, and duplicate photos across listings are a
# fake-listing signal.
PLAN = {
    '10000000-0000-4000-a000-000000000001': [11, 3, 12, 1],   # PS-1001 studio, Kilimani
    '10000000-0000-4000-a000-000000000002': [7, 16, 6],       # PS-1002 1-bed, Kileleshwa
    '10000000-0000-4000-a000-000000000003': [4, 5, 10, 17],   # PS-1003 apartment, Westlands
    '10000000-0000-4000-a000-000000000006': [15],             # PS-1004 1-bed, Ruaka (pending)
    '10000000-0000-4000-a000-000000000004': [18, 9, 8],       # PS-1005 bedsitter, Roysambu
    '10000000-0000-4000-a000-000000000005': [2, 19, 14, 13],  # PS-1006 guest house, South B
}


def local_env():
    supabase = os.path.expanduser('~/.local/bin/supabase-cli/supabase.exe')
    out = subprocess.run([supabase, 'status', '-o', 'env'], capture_output=True, text=True, cwd=ROOT).stdout
    env = dict(line.split('=', 1) for line in out.splitlines() if '=' in line)
    api, key = env['API_URL'].strip('"'), env['SERVICE_ROLE_KEY'].strip('"')
    if '127.0.0.1' not in api and 'localhost' not in api:
        sys.exit('Refusing to run against a non-local Supabase.')
    return api, key


def encode(image, max_width):
    image = image.copy()
    if image.width > max_width:
        image.thumbnail((max_width, max_width * 4))
    buf = io.BytesIO()
    image.save(buf, 'JPEG', quality=82, optimize=True, progressive=True)
    return buf.getvalue(), image.size


def main():
    api, key = local_env()

    def upload(path, data):
        req = urllib.request.Request(
            f'{api}/storage/v1/object/property-images/{path}', data=data, method='POST',
            headers={'Authorization': f'Bearer {key}', 'apikey': key, 'Content-Type': 'image/jpeg',
                     'x-upsert': 'true', 'cache-control': 'max-age=31536000'})
        urllib.request.urlopen(req).read()

    ids = ','.join(f"'{p}'" for p in PLAN)
    sql = ['begin;', f'delete from public.property_images where property_id in ({ids});']
    for pid, numbers in PLAN.items():
        for order, n in enumerate(numbers):
            image = ImageOps.exif_transpose(Image.open(os.path.join(SRC, f'{n}.jpg'))).convert('RGB')
            full, (w, h) = encode(image, 1600)
            thumb, _ = encode(image, 480)
            name = uuid.uuid4().hex
            full_path, thumb_path = f'{OWNER}/{pid}/{name}.jpg', f'{OWNER}/{pid}/{name}_thumb.jpg'
            upload(full_path, full)
            upload(thumb_path, thumb)
            sql.append(
                'insert into public.property_images (property_id, storage_path, thumbnail_path, display_order, '
                f"width, height, caption) values ('{pid}', '{full_path}', '{thumb_path}', {order}, {w}, {h}, null);")
    sql.append('commit;')
    subprocess.run(['docker', 'exec', '-i', 'supabase_db_patastay', 'psql', '-U', 'postgres', '-q', '-v', 'ON_ERROR_STOP=1'],
                   input='\n'.join(sql), text=True, check=True)
    print(f'Linked {sum(len(v) for v in PLAN.values())} photos to {len(PLAN)} sample listings.')


if __name__ == '__main__':
    main()
