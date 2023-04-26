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
	sponge=$(sed 's/\([AB]\)/\1\1\1/g' <<< $sponge)
	sponge=$(sed 's/A/CDC/g;s/B/DED/g' <<< $sponge)

	sponge=$(sed 's/\([CDE]\)/\1\1\1\1\1\1\1\1\1/g' <<< $sponge)

	sponge=$(sed 's/C/XXX/g;' <<< $sponge)
	sponge=$(sed 's/D/XSX/g;' <<< $sponge)
	sponge=$(sed 's/E/SSS/g;' <<< $sponge)

	sponge=$(sed 's/\([XS]\)/\1\1\1\1\1\1\1\1\1/g' <<< $sponge)

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
	chunk+=$one
	chunk+=$(printf '00%.0s' {1..3280})
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000000000000

	#readarray -t two < <(fold -w8192 <<< $two)
	chunk_header
	chunk+=$two
	chunk+=$(printf '00%.0s' {1..3280})
	chunk_footer
	echo "$chunk" > $TEMP/world/FFFFFFFF00000000


	#readarray -t tri < <(fold -w8192 <<< $tri)
	chunk_header
	xhead=$chunk
	xchunk+=$tri
	xchunk+=$(printf '00%.0s' {1..1792})  # fill up current chunk with air
	#chunk+=$(printf '03%.0s' {1..50})    # 16x16x16 block of stone
	chunk+=$xchunk
	chunk+=$(repeat 64 "03")
	chunk+="00 00 00 00 "
	chunk+=$xhead
	chunk+=$xchunk
	chunk_footer
	chunk+="00"
	chunk+="16 00 00 00 00 00 00 00 00"
	#chunk+=$(repeat  1392 "03")  # with 64 + 1393 x '03' we get a full column
	chunk+="09"
	chunk+=$(repeat  1378 "03")
	echo "$chunk" > $TEMP/world/0000000000000001

	#readarray -t tet < <(fold -w8192 <<< $tet)
	chunk_header
	chunk+=$tet
	chunk+=$(printf '00%.0s' {1..3280})
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
