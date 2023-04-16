#!/usr/bin/env bash

spawn_pos=(5 0 5)

function hook_ping() {
	json='{"version":{"name":"1.18.1","protocol":757},"players":{"max":1,"online":0,"sample":[]},"description":{"text":"Menger Sponge"},"favicon":"data:image/png;base64,'"$(base64 -w0 menger.png)"'"}'
	res="$(str_len "$json")$(echo -n "$json" | xxd -p)"
	send_packet "00" "$res"
}

function hook_chunks() {
	# Build 27x27 sponge:
	sponge=ABA
	sponge=$(sed 's/\([AB]\)/\1\1\1/g' <<< $sponge)
	sponge=$(sed 's/A/CDC/g;s/B/DED/g' <<< $sponge)
	sponge=$(sed 's/C/FGF/g;' <<< $sponge)
	sponge=$(sed 's/F/HHH/g;s/G/III/g' <<< $sponge)

	sponge=$(sed 's/\(E\)/\1\1\1\1\1\1\1\1\1/g' <<< $sponge)
	sponge=$(sed 's/F/XXX/g;s/I/XSX/g;s/E/SSS/g' <<< $sponge)
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
	readarray -t one < <(fold -w8192 <<< $one)
	chunk_header
	chunk+=${one[0]}
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000000000000

	chunk_header
	chunk+=${one[1]}
	chunk+=$(printf '00%.0s' {1..1280})
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000000000002

	readarray -t two < <(fold -w8192 <<< $two)
	chunk_header
	#log "DEBUG $(wc -c <<< $two)"

	#log "DEBUG $(wc -c <<< ${two[0]})"
	#log "DEBUG $(wc -c <<< ${two[1]})"
	chunk+=${two[0]}
	#chunk+=$two
	#chunk+=$(printf '12%.0s' {1..1280})
	chunk_footer
	echo "$chunk" > $TEMP/world/FFFFFFFF00000000

	chunk_header
	chunk+=${two[1]}
	log "DEBUG $(wc -c <<< ${two[1]})"
	chunk+=$(printf '00%.0s' {1..1280})
	chunk_footer
	echo "$chunk" > $TEMP/world/FFFFFFFF00000002
	
	readarray -t tri < <(fold -w8192 <<< $tri)
	chunk_header
	chunk+=${tri[0]}
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000000000001

	chunk_header
	chunk+=${tri[1]}
	chunk+=$(printf '00%.0s' {1..1280})
	chunk_footer
	echo "$chunk" > $TEMP/world/0000000000000003
	
	readarray -t tet < <(fold -w8192 <<< $tet)
	chunk_header
	chunk+=${tet[0]}
	chunk_footer
	echo "$chunk" > $TEMP/world/FFFFFFFF00000001

	chunk_header
	chunk+=${tet[1]}
	chunk+=$(printf '00%.0s' {1..1280})
	chunk_footer
	echo "$chunk" > $TEMP/world/FFFFFFFF00000003

	pkt_chunk FFFFFFFF FFFFFFFF 00
	pkt_chunk FFFFFFFF 00000000 00
	pkt_chunk FFFFFFFF 00000001
	pkt_chunk FFFFFFFF 00000002
	pkt_chunk FFFFFFFF 00000003

	pkt_chunk 00000000 FFFFFFFF 00
	pkt_chunk 00000000 00000000
	pkt_chunk 00000000 00000001 00
	pkt_chunk 00000000 00000002
	pkt_chunk 00000000 00000003
	
	pkt_chunk 00000001 FFFFFFFF 00
	pkt_chunk 00000001 00000000 00
	pkt_chunk 00000001 00000001 00
}
