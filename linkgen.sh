#!/usr/bin/env bash
#
# Static link generator
# Created By Roberta Brandao

#linkfile

BASEDIR=$(dirname "$0")
CONF_LINK=./$BASEDIR/conf_link.yml
RENDER_DIR=./public


readarray LIST_ARR < <(yq e '.site_url | keys | .[]' ${CONF_LINK})

# Templating functions
button_template () {
HREF=${1//[$'\n\r\n ']}
VAL=${2//[$'\n\r\n']}
cat <<EOF
<!-- Inicio botao link -->
<div class="text-center"><div style="padding-bottom: 30px;">
<a href="$HREF" target="_blank" class="btn btn-outline-light" style="width: 80%; padding-top:10px; padding-bottom:10px; font-weight: 800;">$VAL</a>
<!-- button onclick="location.href='$HREF'" type="button" class="btn btn-outline-light" style="width: 80%; padding-top:10px; padding-bottom:10px; font-weight: 800;">$VAL</button -->
</div></div>
<!-- Fim botao link -->
EOF
}

create_list_principal () { 
for list in "${LIST_ARR[@]}"
do
   button_template "$list/"  "$list"
done
}

create_index_template () {
export SITE_TITLE=$(yq e '.site_title'  ${CONF_LINK})
export BUTTONS=$(create_list_principal)

   #creating render dirs
   for list in "${LIST_ARR[@]}"
   do
       create_render_dir "${RENDER_DIR}/${list//[$'\n\r\t ']}/assets"
   done

#Creating index page
envsubst < $BASEDIR/index.tpl > $RENDER_DIR/index.html

#copy css and png to assets
create_render_dir "$RENDER_DIR/assets"
cp $BASEDIR/style.tpl $RENDER_DIR/assets/style.css
cp $BASEDIR/image.png $RENDER_DIR/assets/image.png

unset SITE_TITLE
unset BUTTONS
}

create_render_dir () {
[ -d ${1} ] || mkdir -p ${1}
}

create_index_subgroups () {
    #Creating subgroup pages
   for list in "${LIST_ARR[@]}"
   do
    export BUTTONS=''
    export SITE_TITLE="$list Links"

       # creating buttons list
       while IFS= read -r line
       do
           href=$(cat <<< "$line" |  cut -d$'\t' -f2)
           value=$(cat <<< "$line" |  cut -d$'\t' -f1)

           BUTTONS+=$(button_template "${href}" "${value}")
       done < <(yq e ".site_url.$list" ${CONF_LINK} -o=tsv | sed '1d')

    envsubst < $BASEDIR/index.tpl > ${RENDER_DIR}/${list//[$'\n\r\t ']}/index.html

    #copy css and png to assets
    cp $BASEDIR/style.tpl ${RENDER_DIR}/${list//[$'\n\r\t ']}/assets/style.css
    cp $BASEDIR/image.png ${RENDER_DIR}/${list//[$'\n\r\t ']}/assets/image.png
   done


unset SITE_TITLE
unset BUTTONS
}

#Execution

create_index_template
create_index_subgroups
