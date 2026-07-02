#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/BaseballLiveKRApp/Shared/TeamBrandAssets"
MANIFEST="${OUT_DIR}/manifest.json"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36"

mkdir -p "${OUT_DIR}"
tmp_manifest="$(mktemp)"
printf '[\n' > "${tmp_manifest}"
first=1
failed=0

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

download_asset() {
  local team="$1"
  local category="$2"
  local source_page="$3"
  local url="$4"
  local note="${5:-}"
  local team_dir="${OUT_DIR}/${team}/raw"
  local clean_url="${url%%\?*}"
  local original_name
  local filename
  local target

  mkdir -p "${team_dir}"
  original_name="$(basename "${clean_url}")"
  if [[ "${url}" == *"filename="* ]]; then
    original_name="${url##*filename=}"
    original_name="${original_name%%&*}"
  elif [[ "${url}" == *"name="* ]]; then
    original_name="${url##*name=}"
    original_name="${original_name%%&*}"
  fi
  original_name="${original_name//%20/_}"
  original_name="${original_name// /_}"
  filename="${category}__${original_name}"
  target="${team_dir}/${filename}"

  printf 'Downloading %s %s %s\n' "${team}" "${category}" "${url}"
  if ! curl -L --fail --silent --show-error -A "${USER_AGENT}" -o "${target}" "${url}"; then
    printf 'Failed: %s\n' "${url}" >&2
    rm -f "${target}"
    failed=1
    return
  fi

  local bytes sha content_type fetched_at relative_path
  bytes="$(wc -c < "${target}" | tr -d ' ')"
  sha="$(shasum -a 256 "${target}" | awk '{print $1}')"
  content_type="$(file --brief --mime-type "${target}")"
  fetched_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  relative_path="${target#"${ROOT_DIR}/"}"

  if [[ "${first}" -eq 0 ]]; then
    printf ',\n' >> "${tmp_manifest}"
  fi
  first=0

  printf '  {"teamID":"%s","category":"%s","sourcePage":"%s","sourceURL":"%s","filename":"%s","path":"%s","sha256":"%s","bytes":%s,"contentType":"%s","fetchedAt":"%s","note":"%s"}' \
    "$(json_escape "${team}")" \
    "$(json_escape "${category}")" \
    "$(json_escape "${source_page}")" \
    "$(json_escape "${url}")" \
    "$(json_escape "${filename}")" \
    "$(json_escape "${relative_path}")" \
    "$(json_escape "${sha}")" \
    "${bytes}" \
    "$(json_escape "${content_type}")" \
    "$(json_escape "${fetched_at}")" \
    "$(json_escape "${note}")" >> "${tmp_manifest}"
}

asset() {
  download_asset "$@"
}

# KIA Tigers, official CI page and React bundle assets.
asset HT logo "https://tigers.co.kr/tigers/bi/intro" "https://tigers.co.kr/img/download/bi/initial-logo.jpg"
asset HT wordmark "https://tigers.co.kr/tigers/bi/intro" "https://tigers.co.kr/img/download/bi/wordmark.jpg"
asset HT emblem "https://tigers.co.kr/tigers/bi/intro" "https://tigers.co.kr/img/download/emblem/emblem.jpg"
asset HT emblem "https://tigers.co.kr/tigers/bi/intro" "https://tigers.co.kr/img/download/emblem/tiger-emblem.jpg"
asset HT emblem "https://tigers.co.kr/tigers/bi/intro" "https://tigers.co.kr/img/download/emblem/10th-logo.jpg"
asset HT download "https://tigers.co.kr/tigers/bi/intro" "https://tigers.co.kr/img/download/emblem/kia_v_emblem.zip"
for i in "" 01 02 03 04 05 06 07 08 09; do
  asset HT mascot "https://tigers.co.kr/tigers/bi/intro" "https://tigers.co.kr/img/download/mascot/zoom_mascot${i}.jpg"
done

# Doosan Bears, brand page and related Next.js chunk assets.
for path in \
  img_emblem_2025_1.jpg img_emblem_2025_2.jpg \
  img_logo_2025_1.jpg img_logo_2025_2.jpg img_logo_2025_3.jpg img_logo_2025_4.jpg \
  img_symbol_2025_1.jpg img_symbol_2025_2.jpg img_symbol_2025_3.jpg img_symbol_2025_4.jpg \
  img_typography_2025.jpg img_mascot_2025.jpg \
  img_2010_emblem.svg img_emblem.png img_emeblem3.png img_emeblem4.png \
  img_logo_type1.png img_logo_type2.png img_logo_type3.png img_logo_type4.png \
  img_symbol1.png img_symbol2.png img_symbol3.png img_symbol4.png \
  img_mascot2.png img_mascot7.png img_mascot8.png img_mascot9.png img_mascot10.png \
  img_uniform.png img_uniform2.png img_uniform3.png; do
  category="preview"
  [[ "${path}" == *emblem* ]] && category="emblem"
  [[ "${path}" == *logo* ]] && category="logo"
  [[ "${path}" == *symbol* ]] && category="symbol"
  [[ "${path}" == *mascot* ]] && category="mascot"
  [[ "${path}" == *uniform* ]] && category="uniform"
  asset OB "${category}" "https://www.doosanbears.com/bears/brand" "https://www.doosanbears.com/images/${path}"
done

# SSG Landers, emblem page images and S3 downloads.
for path in ssg_emblem1.png ssg_wordmark1.png ssg_wordmark2.png ssg_symbol1.png ssg_symbol2.png ssg_emblem_sub1.png ssg_emblem_sub2.png ssg_emblem3.jpg mascot_randy.png mascot_poorie.png mascot_batty.png; do
  category="emblem"
  [[ "${path}" == *wordmark* ]] && category="wordmark"
  [[ "${path}" == *symbol* ]] && category="symbol"
  [[ "${path}" == mascot* ]] && category="mascot"
  asset SK "${category}" "https://www.ssglanders.com/landers/emblem" "https://www.ssglanders.com/img/wyverns/emblem/${path}"
done
for path in ssg_baseballclub_landers_emblem.zip ssg_baseballclub_landers_wordmark.zip ssg_baseballclub_landers_symbol.zip ssg_baseballclub_landers_sub_emblem.zip ssg_baseballclub_landers_mascot_landy.zip ssg_baseballclub_landers_mascot_poorie.zip ssg_baseballclub_landers_mascot_batty.zip ssg_baseballclub_landers_catchphrase.zip; do
  asset SK download "https://www.ssglanders.com/landers/emblem" "https://ssg-new-prod.s3.ap-northeast-2.amazonaws.com/homepage/emblem/${path}"
done

# KT Wiz, React bundle BI media.
for path in bi_emblem_black.ee614e48.png bi_emblem_white.a8b71dc4.png bi_regular_season_emblem_black.8f57f415.png bi_regular_season_emblem_white.94acb34c.png bi_winner_emblem_black.d34fac8b.png bi_winner_emblem_white.58ddb1a5.png; do
  asset KT emblem "https://www.ktwiz.co.kr/ktwiz/bi/symbol" "https://www.ktwiz.co.kr/static/media/${path}"
done
for path in bi_symbol_image_black.c83e0134.png bi_symbol_image_white.d43524e5.png bi_symbol_initial_black_m.20b17cb0.png bi_symbol_initial_white_m.1bee67fd.png; do
  asset KT symbol "https://www.ktwiz.co.kr/ktwiz/bi/symbol" "https://www.ktwiz.co.kr/static/media/${path}"
done
for path in WordMark_jpg.7bf9c618.jpg WordMark_eng_jpg.b70f7739.jpg bi_mascot_vic.b7b5169a.png bi_mascot_ddory.c5bb98f2.png bi_mascot_vic_and_ddory.8b36e85a.png bi_uniform_img_20251124.b7efbaf7.png; do
  category="wordmark"
  [[ "${path}" == *mascot* ]] && category="mascot"
  [[ "${path}" == *uniform* ]] && category="uniform"
  asset KT "${category}" "https://www.ktwiz.co.kr/ktwiz/bi/symbol" "https://www.ktwiz.co.kr/static/media/${path}"
done
for path in Emblem_ai.6d7ad674.zip Emblem_jpg.692b85eb.jpg ImageSymbol_ai.0bd37d31.zip ImageSymbol_jpg.e6637f0b.jpg InitialSymbol_ai.bd6161ab.zip InitialSymbol_jpg.6ec9821f.jpg WordMark_ai.46c01840.zip WordMark_eng_ai.12fa57d3.zip Mascot_vic_ai.cf54326e.zip Mascot_vic_jpg.7c676cfa.jpg Mascot_ddory_ai.d9a1c867.zip Mascot_ddory_jpg.937ffea0.jpg Mascot_vic_ddory_ai.73cbf553.zip Mascot_vic_ddory_jpg.ac428ee6.zip; do
  asset KT download "https://www.ktwiz.co.kr/ktwiz/bi/symbol" "https://www.ktwiz.co.kr/static/media/${path}"
done

# LG Twins, BI page image assets.
for path in img_emblem01.png img_emblem02.png img_emblem03.png img_logo01.png img_logo02.png img_logo03.png img_logo04.png img_logo05.png img_logo06.png img_mascot01.png img_mascot02.png img_mascot03.png img_mascot04.png img_mascot05.png; do
  category="emblem"
  [[ "${path}" == *logo* ]] && category="logo"
  [[ "${path}" == *mascot* ]] && category="mascot"
  asset LG "${category}" "https://www.lgtwins.com/twins/about/bi" "https://www.lgtwins.com/images/sub/twins/${path}"
done

# Kiwoom Heroes, BI page images and downloads.
for path in imgEmblem11.jpg imgEmblem12.jpg imgEmblem13.jpg imgEmblem14.jpg imgEmblem21.jpg imgEmblem22.jpg imgEmblem23.jpg imgEmblem24.jpg; do
  asset WO emblem "https://heroesbaseball.co.kr/heroes/bi/bi.do" "https://heroesbaseball.co.kr/html/front/web_2018/images/heroes/${path}"
done
for path in imgMascot01.jpg imgMascot02.jpg imgMascot03.jpg imgMascot04.jpg imgMascot05.jpg imgMascot06.jpg; do
  asset WO mascot "https://heroesbaseball.co.kr/heroes/bi/bi.do" "https://heroesbaseball.co.kr/html/front/web/images/heroes/${path}"
done
for name in Kiwoom_heroes_BI.pdf Kiwoom_heroes_BI.ai Goyang_heroes_BI.pdf Goyang_heroes_BI.ai; do
  asset WO download "https://heroesbaseball.co.kr/heroes/bi/bi.do" "https://heroesbaseball.co.kr/heroes/bi-download.do?name=${name}"
done
asset WO download "https://heroesbaseball.co.kr/heroes/bi/bi.do" "https://heroesbaseball.co.kr/files/Mascot_jpg_260206.zip"
asset WO download "https://heroesbaseball.co.kr/heroes/bi/bi.do" "https://heroesbaseball.co.kr/files/Mascot_ai_260206.zip"

# Lotte Giants, BI pcode pages.
for path in bi_eb01.jpg bi_eb02.gif bi_eb03.gif bi_eb04.jpg bi_eb05.jpg bi_eb06.jpg bi_eb07.jpg; do
  asset LT emblem "https://www.giantsclub.com/html/?pcode=213" "https://www.giantsclub.com/html/_Img/intro/${path}"
done
for name in lotte_emblem.ai lotte_emblem.jpg lotte_logo.jpg; do
  asset LT download "https://www.giantsclub.com/html/?pcode=213" "https://www.giantsclub.com/download.asp?no=1&filename=${name}"
done

# NC Dinos, VI page and S3 downloads.
for path in emblem01.png emblem02.png emblem03.png wordmark01.png wordmark02.png wordmark03.png symbolmark02.png symbolmark03.png symbolmark05.png mascots01.png mascots02.png uniform01.jpg uniform02.jpg; do
  category="emblem"
  [[ "${path}" == wordmark* ]] && category="wordmark"
  [[ "${path}" == symbol* ]] && category="symbol"
  [[ "${path}" == mascot* ]] && category="mascot"
  [[ "${path}" == uniform* ]] && category="uniform"
  asset NC "${category}" "https://www.ncdinos.com/dinos/vi.do" "https://www.ncdinos.com/assets/images/sub/${path}"
done
for path in NC_Dinos_Emblem.zip NC_Dinos_Wordmark.zip NC_Dinos_Symbol.zip btn_down_dandi.jpg btn_down_sseri.jpg ncdinos_uniform.jpg; do
  asset NC download "https://www.ncdinos.com/dinos/vi.do" "https://ncdinos-common-bucket.s3.ap-northeast-2.amazonaws.com/v1/etc/vi/${path}"
done

# Samsung Lions, official emblem/character tabs and downloads.
for path in img_wordmark.png img_emblem.png img_champion.png img_mascot.png img_uniform.png img_color.png img_logotype.png img_initial.png img_signature.png img_mascot2.png img_mascotemblem.png img_mascotsigniture.png bleo_fam_main.png bleo_fam_emblem.png Catchphrase_2023.jpg 2018_Catchphrase_blue.png 2018_Catchphrase_white.png; do
  category="preview"
  [[ "${path}" == *wordmark* || "${path}" == *logotype* ]] && category="wordmark"
  [[ "${path}" == *emblem* || "${path}" == *initial* || "${path}" == *champion* ]] && category="emblem"
  [[ "${path}" == *mascot* || "${path}" == *bleo* ]] && category="mascot"
  [[ "${path}" == *uniform* ]] && category="uniform"
  [[ "${path}" == *Catchphrase* ]] && category="slogan"
  asset SS "${category}" "https://www.samsunglions.com/intro/intro04.asp" "https://www.samsunglions.com/img/intro/${path}"
done
for path in ai_1_1.zip jpg_1_1.zip ai_1_2.zip jpg_1_2.zip champions.zip ai_1_3.zip jpg_1_3.zip ai_1_4.zip jpg_1_4.zip ai_1_5.zip jpg_1_5.zip ai_2_1.zip jpg_2_1.zip ai_2_2.zip jpg_2_2.zip ai_2_3.zip jpg_2_3.zip ai_3_2.zip jpg_3_2.zip bleo_fam.zip bleo_fam_emblem.zip bleo_fam_jpg.zip Catchphrase_2023_ai.zip Catchphrase_2023_jpg.zip; do
  asset SS download "https://www.samsunglions.com/intro/intro04.asp" "https://www.samsunglions.com/img/intro/emblem/${path}"
done

# Hanwha Eagles, official domain currently exposes BI-like assets through the 2024 new BI gallery and game BI image paths.
for path in fd452503-3dcf-49a3-b7b0-97401d7dcf21.png 7f9c4cc2-9d70-4ffb-bdb4-b89d8f3863a9.png 1ddae7ac-8c73-4543-b8e7-73d90e9e5c7b.png 49c99650-5708-4fc0-b0f4-829db5649114.png e50dcd10-4325-49b4-9cb6-6c9afaf37fb6.png 7d10c327-e252-42ff-83d7-b198283a00b0.png fa7aff34-adb7-45a5-ba8b-82c524272367.png c757d6f0-7f83-4d95-8214-c2d4f1b30aa5.png; do
  asset HH preview "https://www.hanwhaeagles.co.kr/FA/CN/PCFACN02.do?id=1699" "https://www.hanwhaeagles.co.kr/202411/${path}" "limited_source"
done
asset HH emblem "https://www.hanwhaeagles.co.kr/index.do" "https://www.hanwhaeagles.co.kr/images/pages/game/bi_game_hanwha.png" "limited_source"

printf '\n]\n' >> "${tmp_manifest}"
mv "${tmp_manifest}" "${MANIFEST}"

if [[ "${failed}" -ne 0 ]]; then
  printf 'Completed with failed downloads. See log above.\n' >&2
  exit 1
fi

printf 'Manifest written: %s\n' "${MANIFEST}"
