#!/usr/bin/env bash

spawn_pos=(5 0 5)

function hook_ping() {
	json='{"version":{"name":"1.18.1","protocol":757},"players":{"max":1,"online":0,"sample":[]},"description":{"text":"Menger Sponge"},"favicon":"data:image/png;base64,'"$(base64 -w0 demos/menger.png)"'"}'
	res="$(str_len "$json")$(echo -n "$json" | xxd -p)"
	send_packet "00" "$res"
}

function hook_chunks() {
	# Build 27x27 sponge:
	sponge=ABA
	sponge=$(sed 's/A/CDC/g;s/B/EFE/g' <<< $sponge)
	sponge=$(sed 's/\([CDEF]\)/\11\12\11/g' <<< $sponge)
	sponge=$(sed 's/C1/aba/g;s/C2/cdc/g' <<< $sponge)
	sponge=$(sed 's/D1/efe/g;s/D2/ghg/g' <<< $sponge)
	sponge=$(sed 's/E1/imi/g;s/E2/jmj/g' <<< $sponge)
	sponge=$(sed 's/F1/kmk/g;s/F2/lml/g' <<< $sponge)

	sponge=$(sed "s/a/N3TVT3UVU3TVTN /g;s/N/9T9U9T /g" <<< $sponge)
	sponge=$(sed "s/b/N TVT3V TVT UVU3V UVU TVT3V TVT N /g;s/N/3T3V3T3U3V3U3T3V3T /g" <<< $sponge)
	sponge=$(sed "s/[ceg]/$(repeat 81 T)/g" <<< $sponge)
	sponge=$(sed "s/[dfh]/$(repeat 9 "TTTVVVTTT")/g" <<< $sponge)
	sponge=$(sed "s/[ijkl]/$(repeat 9 "TTTVVVTTT")/g" <<< $sponge)
	sponge=$(sed "s/m/$(repeat 81 V)/g" <<< $sponge)
	sponge=$(sed "s/9\([A-Z]*\)/3\13\13\1 /g;s/3\([A-Z]*\)/\1\1\1 /g" <<< $sponge)
	sponge=$(sed 's/\s//g;s/T/XXX/g;s/U/XSX/g;s/V/SSS/g' <<< $sponge)

	# Split sponge into 4 16x16 chunks:
	i=0
	while read row; do
		read a b < <(sed "s/^\(.\{6\}\)\(.\{8\}\)\(.\{8\}\)\(.\{5\}\)$/\2SS\1 \4SSS\3/" <<< $row)
		log $row $i
		if (( i == 0 )); then
		  one+=$(printf '00%.0s' {1..32})
		  two+=$(printf '00%.0s' {1..32})
		fi
		if (( i < 14 )); then
		  one+=$(sed 's/X/13/g;s/S/00/g' <<< $a)
		  two+=$(sed 's/X/12/g;s/S/00/g' <<< $b)
		else
		  tri+=$(sed 's/X/13/g;s/S/00/g' <<< $a)
		  tet+=$(sed 's/X/13/g;s/S/00/g' <<< $b)
		fi
		((i+=1))
		if (( i == 27 )); then
		  i=0
		  tri+=$(printf '00%.0s' {1..48})
                  tet+=$(printf '00%.0s' {1..48})
	       	fi
	done < <(fold -w27 <<< $sponge)

	# and split chunk cols into 16x16x16 chunk sections 
	# since idk how to render full cols...

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

	pkt_chunk FFFFFFFF FFFFFFFF
	pkt_chunk FFFFFFFF 00000000  # two
	pkt_chunk FFFFFFFF 00000001  # four
	pkt_chunk FFFFFFFF 00000002 00
	pkt_chunk FFFFFFFF 00000003 00

	pkt_chunk 00000000 FFFFFFFF 00
	pkt_chunk 00000000 00000000   # one
	pkt_chunk 00000000 00000001   # three
	pkt_chunk 00000000 00000002 00
	pkt_chunk 00000000 00000003 00
	
	pkt_chunk 00000001 FFFFFFFF 00
	pkt_chunk 00000001 00000000 00
	pkt_chunk 00000001 00000001 00
}
