#!/bin/bash
# ----------------------------------------------------------------------------------
# @name    : kissanime-dl
# @version : 0.1
# @date    : 25/10/2013 11:21:59
#
# TENTANG
# ----------------------------------------------------------------------------------
# Script untuk link-grabbing (mengambil link) download video dari kissanime.com,
# bisa mengambil link video untuk semua episode, bisa satu episode tertentu.
# Setelah grabbing link, script akan membuat halaman html yang berisi link
# video dari hasil grabbing tersebut.
#
# CHANGELOG
# ----------------------------------------------------------------------------------
# versi 0.1 - 25/10/2013 11:21:59
#     - Rilis pertama.
#     - Working.. Bisa ambil link semua episode atau satu episode saja.
#     - Bisa pake proxy, pilih proxy secara acak untuk koneksi, acak tapi smart,
#       jika proxy sukses konek, maka koneksi selanjutnya akan tetap memakai proxy
#       itu, tapi bila gagal konek, koneksi selanjutnya akan memakai proxy lain.
#     - Ada opsi untuk mengambil link video 720p, 480p, 360p atau 240p
#     - Mampu fallback, kalau tidak menemukan link video dengan resolusi yang
#       ditentukan, akan mengambil video dengan resolusi di bawahnya.
#     - Halaman html hasil generate-an lumayan cantik :)
#
#     - UPDATE: 28/10/2013 11:35:46
#       Kissanime.com membolkir script ini, semua link video yang dihasilkan script
#       ini menjadi tidak valid ("This app steals video from kissanime.com").
#       Link yang tidak valid hanya link ke-2 dst, mungkin perlu menerapkan cookie,
#       cache atau semacamnya (belum ketemu T.T)
#       05/11/2013 11:18:52 - Setelah baca ini (http://is.gd/cyberciti_wget)
#       Terpikirkan kalau curl diganti wget saja. belum dicoba sih, terutama untuk
#       download banyak (bulk download), nanti saja kalau ada waktu dicoba.
#
#     - UPDATE: 16/11/2013 15:41:08
#       Pakai cara wget ternyata tetap ndak bisa, kissanime.com yang menggunakan
#       proteksi dari cloudflare awalnya, sekarang menggunakan incapsula.
#       Sepertinya proteksi semacam itu otomatis memblokir akses dari curl atau
#       wget. #stuck
#
# KONTAK
# ----------------------------------------------------------------------------------
# Ada bug? saran? sampaikan ke saya.
# Ghozy Arif Fajri / gojigeje
# email    : gojigeje@gmail.com
# web      : goji.web.id
# facebook : facebook.com/gojigeje
# twitter  : @gojigeje
# G+       : gplus.to/gojigeje
#
# LISENSI
# ----------------------------------------------------------------------------------
# Open Source tentunya :)
#  The MIT License (MIT)
#  Copyright (c) 2013 Ghozy Arif Fajri <gojigeje@gmail.com>

# Gunakan Proxy untuk koneksi ? 1 / 0
useProxy=0

# List IP dan port Proxy
proxyList=(
  # "IP:PORT"
  # "IP:PORT"
)

getProxy() {
  if [[ useProxy -gt 0 ]]; then
    if [[ changeProxy -gt 0 ]]; then
      n=1
      for index in `shuf --input-range=0-$(( ${#proxyList[*]} - 1 )) | head -${n}`
      do
        proxy=${proxyList[$index]}
        proxy=$(echo $proxy | sed 's/^/\-m '$proxyTimeout' \-x /g')
      done

      proxyinfo="[proxy$index]"
    fi
      else
        proxyinfo="[direct]"
  fi
}

cek_koneksi() {
  if eval "ping -c 1 8.8.4.4 -w 2 > /dev/null"; then
    echo "# `date +%Y-%m-%d:%H%M` - Cek koneksi internet.. [OK] "
  else
    echo "# `date +%Y-%m-%d:%H%M` - EXIT: Nggak konek internet :("
    exit
  fi
}

mulai() {
   clear
   figlet " KissAnime-DL"
   echo "  KissAnime.com link grabber by @gojigeje <gojigeje@gmail.com>"
   echo ""
   cek_koneksi
   cekResolusi $2
   cekLink $1
   verifyPage $1 $2
}

cekResolusi() {
  if [ "$1" = "720" -o "$1" = "480" -o "$1" = "360" -o "$1" = "240" -o  "$1" = "" ]; then
    # SETTINGS, DONT EDIT !!!
    tempFile=".kisstemp"
    tempLink=".kisstempLink"
    linkFile=".kisslink"
    downloadFile="download.html"
    fallback=0
    changeProxy=1
    proxyTimeout=20
  else
    echo "#"
    echo "# [-ERROR-] Parameter resolusi video salah!"
    echo "#           Gunakan 720, 480, 360, 240 atau tanpa parameter."
    echo "#"
    echo "# Script akan keluar."
    echo "#"
    exit
  fi
}

cekLink() {
   link=$1
   cLink=$(echo $link | sed 's/http:\/\///g' | sed 's/\/$//g')
   cSitus=$(echo $cLink | cut -d "/" -f1)
   cAnime=$(echo $cLink | cut -d "/" -f2)
   cJudul=$(echo $cLink | cut -d "/" -f3)
   cEpisode=$(echo $cLink | cut -d "/" -f4)

   # echo "$cSitus $cAnime $cJudul $cEpisode"

   if [ "$cSitus" = "kissanime.com" -o "$cSitus" = "www.kissanime.com" ]; then
      if [[ -z "$cEpisode" ]]; then
         if [[ -z "$cJudul" ]]; then
            linkSalah="1"
         else
            if [[ "$cAnime" = "Anime" ]]; then
               dlTipe="Anime"
            else
               linkSalah="1"
            fi
         fi
      else
         adaEpisode=$(echo $cEpisode | grep "Episode" | wc -l)
         if [[ $adaEpisode -gt 0 ]]; then
            dlTipe="Episode"
         else
            linkSalah="1"
         fi
      fi
   else
      linkSalah="1"
   fi

   if [[ $linkSalah -gt 0 ]]; then
      echo "#"
      echo "# [-ERROR-] Link Salah! Script hanya bisa mengunduh episode dari situs KissAnime.com"
      echo "#           Pastikan link yang dimasukkan benar!"
      echo "#"
      echo "#           Untuk mengunduh semua Episode: "
      echo "#            - http://www.kissanime.com/Anime/[judul Anime]"
      echo "#           Untuk mengunduh satu Episode: "
      echo "#            - http://www.kissanime.com/Anime/[judul Anime]/Episode-XXX"
      echo "#"
      echo "# Script akan keluar."
      cleanUp
      exit 1
   else
      curlPage $1
   fi
}

curlPage() {
  echo "#"
  echo "# Mengunduh halaman: $1"
  getProxy
  curl -s $proxy $1 > $tempFile # pake proxy
}

verifyPage() {
   echo "#"
   echo -n "# Memeriksa struktur halaman.."

   header=$(grep "<html" $tempFile | wc -l)
   footer=$(grep "</html>" $tempFile | wc -l)

   if [[ $header = 1 ]]; then
      if [[ $footer = 1 ]]; then
         fileStat="OK"
      else
         fileStat="KO"
      fi
   else
     fileStat="KO"
   fi

   if [[ $fileStat = "OK" ]]; then
      echo " [OK]"

      if [[ "$dlTipe" = "Anime" ]]; then
        getAnime $1 $2
      else
        getEpisode $1
      fi

   else
      echo ""
      echo "#"
      echo "# [-ERROR-] Struktur halaman tidak sesuai!"
      echo "#           Biasanya disebabkan karena proses mengunduh yang tidak sempurna."
      echo "#           Periksa juga koneksi internet."
      echo "#"
      echo "# Script akan keluar.."
      cleanUp
      exit 1
   fi
}

getAnime() {
   judulAnime=$(cat $tempFile | grep bigChar | head -n1 | sed 's/<[^>]\+>/ /g' | sed "s/[ \t]*//$g" | sed 's/ $//g')
   deskripsiAnime=$(cat $tempFile | awk -F: '/Summary:/ && $0 != "" { getline; print $0}')
   downloadFile="$HOME/Desktop/$judulAnime.html"
   echo "#"
   echo "# Judul Anime: '$judulAnime'"

   awk '/<table\>/{a=1;next}/<\/table\>/{a=0}a' $tempFile | grep "<a href=" > $tempLink
   cat $tempLink | grep -o '<a .*href=.*>' | sed -e 's/<a /\n<a /g' | sed -e 's/<a .*href=['"'"'"]//' -e 's/["'"'"'].*$//' -e '/^$/ d' | sed 's/^/http:\/\/kissanime.com/g' > $linkFile
   jumlahEpisode=$(awk '/<table\>/{a=1;next}/<\/table\>/{a=0}a' $tempFile | grep "<a href=" | wc -l)
   echo "# Jumlah Link Video: $jumlahEpisode"

   tac $tempLink > $tempLink.tac
   tac $linkFile > $linkFile.tac
   rm $tempLink $linkFile
   mv $tempLink.tac $tempLink
   mv $linkFile.tac $linkFile

   # cat $tempLink | sed 's/^.*anime //; s/online.*$//' > $titleFile
   generateLinks $1 $2
}

getEpisode() {
  judulAnime=$(cat $tempFile | grep "itemprop=\"name\"" | sed 's/^.*content="//g' | sed 's/"\/>//g')
  downloadFile="$HOME/Desktop/$judulAnime.html"

  echo "#"
  echo "# Judul Episode: $judulAnime"
  echo "#"
  echo "# Mengambil link download.. $proxyinfo"

  echo "<!-- Generated using KissAnime-DL Script by @gojigeje <gojigeje@gmail.com> -->" > "$downloadFile"
  echo "" >> "$downloadFile"
  echo "<html><head><title>Download $judulAnime</title><style>div{width:75%;padding:10px;margin:0 auto;background:#D5F1FF;}.judul{background:#86D0F4;text-align:center;font-size:20px;}#deskripsi{text-align:center;}.listing{text-align:center;}.listing:hover{background:#FEFFD6;}#footer{background:#86D0F4;text-align:center;font-size:12px;}.merah{color:#FF2A2A;}</style></head><body><div class='judul'><a href='$1' target='_blank'>Download $judulAnime</a></div>" >> "$downloadFile"

  while [[ true ]]; do
    > $tempFile
    echo -n "# - $judulAnime.."
    sleep 5
    getDlLinks $1 > $tempFile

    if [ -s "$tempFile" ]; then
      echo "<div class='listing'>" >> "$downloadFile"
      echo "$judulAnime <br>" >> "$downloadFile"
      cat $tempFile >> "$downloadFile"

      echo " $proxyinfo - [OK]"
      changeProxy=0
      break
    else
      echo " $proxyinfo - [RETRY]"
      changeProxy=1
    fi

  done

  echo "<div id='footer'>Generated using KissAnime-DL Script by @gojigeje &lt;gojigeje@gmail.com&gt;</div>" >> "$downloadFile"
  echo "</body></html>" >> "$downloadFile"
  echo "#"
  echo "# Link download disimpan sebagai \"$downloadFile\""
  echo "#"
  echo "# `date +%Y-%m-%d:%H%M` - Selesai!"

  cleanUp
}

generateLinks() {
   echo "#"
   echo "# Mengambil link download.. $proxyinfo"

   echo "<!-- Generated using KissAnime-DL Script by @gojigeje <gojigeje@gmail.com> -->" > "$downloadFile"
   echo "" >> "$downloadFile"
   echo "<html><head><title>Download $judulAnime</title><style>div{width:75%;padding:10px;margin:0 auto;background:#D5F1FF;}.judul{background:#86D0F4;text-align:center;font-size:20px;}#deskripsi{text-align:center;}.listing{text-align:center;}.listing:hover{background:#FEFFD6;}#footer{background:#86D0F4;text-align:center;font-size:12px;}.merah{color:#FF2A2A;}</style></head><body><div class='judul'><a href='$1' target='_blank'>Download $judulAnime</a></div>" >> "$downloadFile"
   echo "<div id='deskripsi'>$deskripsiAnime</div>" >> "$downloadFile"

   case "$2" in
    "720" )
      echo "# Memilih link video 720p.."
      pixel="[720p]"
    ;;
    "480" )
      echo "# Memilih link video 480p.."
      pixel="[480p]"
    ;;
    "360" )
      echo "# Memilih link video 360p.."
      pixel="[360p]"
    ;;
    "240" )
      echo "# Memilih link video 240p.."
      pixel="[240p]"
    ;;
    *)
      echo "# Memilih semua link video.."
      pixel="[All Links]"
    ;;
   esac

   echo "<div class='judul'>Download Link $pixel</div>" >> "$downloadFile"

   eps=$(cat $linkFile | wc -l)
   max=$(( $eps + 1 ))
   num=1
   while [[ num -lt max ]];
      do
         > $tempFile
         line="`sed -n "$num"p $linkFile`"
         judulTemp="`sed -n "$num"p $tempLink`"
         judul=$(echo $judulTemp | sed 's/^.*anime //; s/online.*$//' | sed 's/ $//g')

         if [[ $fallback -eq 480 ]]; then
           echo "# Mencoba link video 480p.."
           pixel="[480p]"
           getDlLinks480 $line > $tempFile
         elif [[ $fallback -eq 360 ]]; then
           echo "# Mencoba link video 360p.."
           pixel="[360p]"
           getDlLinks360 $line > $tempFile
         elif [[ $fallback -eq 240 ]]; then
           echo "# Mencoba link video 240p.."
           pixel="[240p]"
           getDlLinks240 $line > $tempFile
         elif [[ $fallback -eq 1 ]]; then
           echo "# Mengambil semua link video.."
           pixel="[All Links]"
           getDlLinks $line > $tempFile
         elif [[ $fallback -eq 0 ]]; then
           case "$2" in
            "720" )
              getDlLinks720 $line > $tempFile
            ;;
            "480" )
              getDlLinks480 $line > $tempFile
            ;;
            "360" )
              getDlLinks360 $line > $tempFile
            ;;
            "240" )
              getDlLinks240 $line > $tempFile
            ;;
            *)
              getDlLinks $line > $tempFile
            ;;
           esac
         fi

         echo -n "# - $judul..$pixel"
         sleep 5

         if [ -s "$tempFile" ]; then

            if [[ $fallback -lt 1 ]]; then
                echo "<div class='listing'>" >> "$downloadFile"
                echo "$judul <br>" >> "$downloadFile"
            fi

            nf=$(cat $tempFile)
            if [[ "$nf" == *"tidak ditemukan"* ]]
               then
               alt=$(cat $tempFile)
               echo "$alt | " >> "$downloadFile"
               echo " $proxyinfo - [NOT FOUND!]"

               if [[ $fallback -eq 480 ]]; then
                 fallback=360
               elif [[ $fallback -eq 360 ]]; then
                 fallback=240
               elif [[ $fallback -eq 240 ]]; then
                 fallback=1
               elif [[ $fallback -eq 1 ]]; then
                 fallback=0
               elif [[ $fallback -eq 0 ]]; then
                 case "$2" in
                  "720" )
                    fallback=480
                  ;;
                  "480" )
                    fallback=360
                  ;;
                  "360" )
                    fallback=240
                  ;;
                  "240" )
                    fallback=1
                  ;;
                  *)
                    fallback=0
                  ;;
                 esac
               fi
               continue
            else
               cat $tempFile >> "$downloadFile"
               echo " $proxyinfo - [OK]"
               case "$2" in
                "720" )
                  pixel="[720p]"
                ;;
                "480" )
                  pixel="[480p]"
                ;;
                "360" )
                  pixel="[360p]"
                ;;
                "240" )
                  pixel="[240p]"
                ;;
                *)
                  pixel="[All Links]"
                ;;
               esac
               fallbackBefore=0
               fallback=0
            fi

            changeProxy=0
            let num++;
         else
            echo " $proxyinfo - [RETRY]"
            changeProxy=1
            continue
         fi

   done

   echo "<div id='footer'>Generated using KissAnime-DL Script by @gojigeje &lt;gojigeje@gmail.com&gt;</div>" >> "$downloadFile"
   echo "</body></html>" >> "$downloadFile"
   echo "#"
   echo "# Link download disimpan sebagai \"$downloadFile\""
   echo "#"
   echo "# `date +%Y-%m-%d:%H%M` - Selesai!"
   cleanUp
}

getDlLinks() {
   getProxy
   curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g'
}

getDlLinks720() {
  getProxy

  curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' > $tempFile
  mp4=$(cat $tempFile | grep "x720.mp4" | wc -l)
  flv=$(cat $tempFile | grep "x720.flv" | wc -l)
  > $tempFile

  if [[ $mp4 -gt 0 ]]; then
    resolusi="x720.mp4"
    curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' | grep "$resolusi" | sed 's/$/<\/div>/g'
  elif [[ $flv -gt 0 ]]; then
    resolusi="x720.flv"
    curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' | grep "$resolusi" | sed 's/$/<\/div>/g'
  else
    echo "<span class='merah'>Link video 240p tidak ditemukan.</span>"
  fi
}

getDlLinks480() {
  getProxy

  curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' > $tempFile
  wide480=$(cat $tempFile | grep "854x4" | wc -l)
  old480=$(cat $tempFile | grep "640x48" | wc -l)
  other480=$(cat $tempFile | grep "0x480" | wc -l)
  > $tempFile

  if [[ $wide480 -gt 0 ]]; then
    resolusi="854x4"
    curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' | grep "$resolusi" | sed 's/$/<\/div>/g'
  elif [[ $old480 -gt 0 ]]; then
    resolusi="640x48"
    curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' | grep "$resolusi" | sed 's/$/<\/div>/g'
  elif [[ $other480 -gt 0 ]]; then
    resolusi="0x480"
    curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' | grep "$resolusi" | sed 's/$/<\/div>/g'
  else
    echo "<span class='merah'>Link video 480p tidak ditemukan.</span>"
  fi
}

getDlLinks360() {
  getProxy

  curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' > $tempFile
  flv=$(cat $tempFile | grep "0x360.flv" | wc -l)
  mp4=$(cat $tempFile | grep "0x360.mp4" | wc -l)
  > $tempFile

  if [[ $flv -gt 0 ]]; then
    resolusi="0x360.flv"
    curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' | grep "$resolusi" | sed 's/$/<\/div>/g'
  elif [[ $mp4 -gt 0 ]]; then
    resolusi="0x360.mp4"
    curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' | grep "$resolusi" | sed 's/$/<\/div>/g'
  else
    echo "<span class='merah'>Link video 360p tidak ditemukan.</span>"
  fi
}

getDlLinks240() {
  getProxy

  curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' > $tempFile
  flv=$(cat $tempFile | grep "x240.flv" | wc -l)
  mp4=$(cat $tempFile | grep "x240.mp4" | wc -l)
  > $tempFile

  if [[ $flv -gt 0 ]]; then
    resolusi="x240.flv"
    curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' | grep "$resolusi" | sed 's/$/<\/div>/g'
  elif [[ $mp4 -gt 0 ]]; then
    resolusi="x240.mp4"
    curl -s $proxy $1 | grep "Save as" | sed 's/Download (Save as...): //g' | sed 's/ - /\n/g' | grep "$resolusi" | sed 's/$/<\/div>/g'
  else
    echo "<span class='merah'>Link video 240p tidak ditemukan.</span>"
  fi
}

cleanUp() {
   rm $tempFile $tempLink $linkFile > /dev/null 2>&1
   echo "#"
}

# cek parameter
if [ -z "$1" ]
  then
    echo " U want me to kiss what??"
    echo " $0 [url]"
    exit
  else
    mulai $1 $2
fi
