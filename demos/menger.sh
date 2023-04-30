#!/usr/bin/env bash

spawn_pos=(5 0 5)

function hook_ping() {
	json='{"version":{"name":"1.18.1","protocol":757},"players":{"max":1,"online":0,"sample":[]},"description":{"text":"Menger Sponge"},"favicon":"data:image/png;base64,'"$(base64 -w0 demos/menger.png)"'"}'
	res="$(str_len "$json")$(echo -n "$json" | xxd -p)"
	send_packet "00" "$res"
}

function swp() {
	sed "s/U/V/g;s/T/U/g" <<< $1
}

function blk() {
	sed 's/X/13/g;s/S/00/g' <<< $1
}

function hook_chunks() {
	# Build Level 4 (27x27x27) sponge:
	n="N9V9V9VN /g;s/N/"
	o=" TVT3V TVTUVU3V UVUTVT3V TVT "
	a="N3TVT3UVU3TVTN /g;s/N/9T9U9T /g"
	b="N${o}N /g;s/N/3T3V3T3U3V3U3T3V3T /g"
	e="$n 3TVT3UVU3TVT /g"
	f="$n$o/g"
	c=$(swp "$a")
	d=$(swp "$b")
	g=$(swp "$e")
	h=$(swp "$f")
	sponge=$(sed "s/A/CDC/g;s/B/EFE/g;
		s/\([CDEF]\)/\11\12\11/g;
		s/C1/aba/g;s/C2/cdc/g;
		s/D1/efe/g;s/D2/ghg/g;
		s/E1/bmb/g;s/E2/dmd/g;
		s/F1/fmf/g;s/F2/hmh/g;
		$(for i in {a..h}; do printf "s/${i}/${!i};";done)
		s/m/$(repeat 81 V)/g;
		s/9\([A-Z]*\)/3\13\13\1 /g;s/3\([A-Z]*\)/\1\1\1 /g;
		s/\s//g;s/T/XXX/g;s/U/XSX/g;s/V/SSS/g" <<< ABA)
		#          Triple/   Un/       Void

	# Split sponge into 4 16x16 chunks:
	i=0
	gap=$(repeat 48 00)
	while read row; do
		read a b < <(sed "s/^\(.\{6\}\)\(.\{8\}\)\(.\{8\}\)\(.\{5\}\)$/\2SS\1 \4SSS\3/" <<< $row)
		log $row $i
		if (( i == 0 )); then
		  one+=$(repeat 32 00)
		  two+=$(repeat 32 00)
		fi
		if (( i < 14 )); then
		  one+=$(blk "$a")
		  two+=$(blk "$b")
		else
		  tri+=$(blk "$a")
		  tet+=$(blk "$b")
		fi
		((i+=1))
		if (( i == 27 )); then
		  i=0; tri+=$gap; tet+=$gap
	       	fi
	done < <(fold -w27 <<< $sponge)

	#readarray -t one < <(fold -w8192 <<< $one)
	chunk_header
	xhead=$chunk
	chunk+=${one::8192}000100$xhead
	chunk+=${one:8192}$(repeat $((8192 - $(wc -c <<< ${one:8192}) + 1)) 0)
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000000000000

	#readarray -t two < <(fold -w8192 <<< $two)
	chunk_header
	xhead=$chunk
	chunk+=${two::8192}000100$xhead
	chunk+=${two:8192}$(repeat $((8192 - $(wc -c <<< ${two:8192}) + 1)) 0)
	chunk_footer
	echo "$chunk" > $TEMP/world/FFFFFFFF00000000


	#readarray -t tri < <(fold -w8192 <<< $tri)
	chunk_header
	xhead=$chunk
	chunk+=${tri::8192}
	chunk+="00 01 00"
	chunk+=$xhead
	chunk+=${tri:8192}$(repeat $((8192 - $(wc -c <<< ${tri:8192}) + 1)) 0)
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000000000001

	#readarray -t tet < <(fold -w8192 <<< $tet)
	chunk_header
	xhead=$chunk
	chunk+=${tet::8192}000100$xhead
	chunk+=${tet:8192}$(repeat $((8192 - $(wc -c <<< ${tet:8192}) + 1)) 0)
	chunk_footer
	echo "$chunk" > $TEMP/world/FFFFFFFF00000001

	#pkt_chunk FFFFFFFF FFFFFFFF 00
	pkt_chunk FFFFFFFF 00000000  # two
	pkt_chunk FFFFFFFF 00000001  # four
	#pkt_chunk FFFFFFFF 00000002 00
	#pkt_chunk FFFFFFFF 00000003 00

	#pkt_chunk 00000000 FFFFFFFF 00
	pkt_chunk 00000000 00000000   # one
	pkt_chunk 00000000 00000001   # three
	#pkt_chunk 00000000 00000002 00
	#pkt_chunk 00000000 00000003 00
	
	#pkt_chunk 00000001 FFFFFFFF 00
	#pkt_chunk 00000001 00000000 00
	#pkt_chunk 00000001 00000001 00
}
