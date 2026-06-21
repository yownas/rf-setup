#!/usr/bin/env bash

# Place this script in an empty folder where you want your RuinedFooocus installation
# Make sure it is executable with: chmod 755 rf-setup.sh
# Run it: ./rf-setup.sh

python_embeded_dir="python_embeded"
python_urls=(
  "3.10.20 x86_64|https://github.com/astral-sh/python-build-standalone/releases/download/20260602/cpython-3.10.20+20260602-x86_64-unknown-linux-gnu-pgo+lto-full.tar.zst"
  "3.13.13 x86_64|https://github.com/astral-sh/python-build-standalone/releases/download/20260602/cpython-3.13.13+20260602-x86_64-unknown-linux-gnu-pgo+lto-full.tar.zst"
)
python_modules="wheel packaging pygit2 setuptools==80.9.0"
ruinedfooocus_dir="RuinedFooocus"
ruinedfooocus_repo="https://github.com/runew0lf/RuinedFooocus/"
ruinedfooocus_branches=(
  "main (recommended)"
  "development"
)
torch_options=(
  "Auto ((Remove current Torch and let RF install its prefered version at startup)|auto"
  "CUDA 12.4 (Older GTX gpus)|https://download.pytorch.org/whl/cu124/"
  "CUDA 12.8 (GTX1660, RTX20xx and up)|https://download.pytorch.org/whl/cu128/"
  "CUDA 13.0 (RTX20xx and up, DGX Spark)|https://download.pytorch.org/whl/cu130/"
  "CUDA 13.2 (nightly)|https://download.pytorch.org/whl/nightly/cu132/"
  "RDNA 3 (RX 7000)|https://rocm.nightlies.amd.com/v2/gfx110X-all/"
  "RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)|https://rocm.nightlies.amd.com/v2/gfx1151/"
  "RDNA 4 (RX 9000)|https://rocm.nightlies.amd.com/v2/gfx120x-all/"
  "cpu|https://download.pytorch.org/whl/cpu"
  "Freeze current version|freeze"
  "Unfreeze (RF might update Torch automatically)|unfreeze"
)

tput civis
trap 'tput cnorm' EXIT

header() {
  echo -n "python: "
  [[ -d "$python_embeded_dir" ]] && echo -n "installed" || echo -n "missing"
  echo -n " | RuinedFooocus: "
  [[ -d "$ruinedfooocus_dir" ]] && echo -n "installed" || echo -n "missing"
  echo
  echo "Use ↑ ↓ and Enter"
  echo
}

draw_menu() {
  clear
  header
  for i in "${!options[@]}"; do
    if [[ $i == $selected ]]; then
      printf "\e[7m > %s \e[0m\n" "${options[$i]}"
    else
      printf "   %s\n" "${options[$i]}"
    fi
  done
}

menu() {
  selected=0
  while true; do
    draw_menu
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 key

      case "$key" in
        '[A')
          ((selected--))
          ;;
        '[B')
          ((selected++))
          ;;
      esac
      ((selected<0)) && selected=$((${#options[@]}-1))
      ((selected>=${#options[@]})) && selected=0

    elif [[ $key == "" ]]; then
      break
    fi
  done
}

python_install() {
  url=$(echo "${python_urls[$1]}" | cut -d'|' -f2)
  clear
  header
  if [ -d "$python_embeded_dir" ]; then
    echo "Sorry, you already have a python_embeded."
    echo "Press enter to continue."
  else
    wget -O python.tar.zst "$url"
    tar xvf python.tar.zst --transform="s|^python/install|${python_embeded_dir}|" python/install
    echo "Install required modules."
    $python_embeded_dir/bin/pip install $python_modules
    echo;echo "Done... (Press enter)"
  fi
  read
}
python_loop() {
  while true; do
    options=()
    for url in "${python_urls[@]}"; do
      options+=("$(echo $url|cut -d'|' -f1)")
    done
    options+=("Back")
    menu
    if [ $selected -lt ${#python_urls[@]} ]; then
      python_install $selected
    else
      break
    fi
  done
}

git_clone() {
  clear
  header
  if [ -d "$ruinedfooocus_dir" ]; then
    echo "Sorry, you already have RuinedFooocus downloaded."
    read
  else
    echo "Using branch ${ruinedfooocus_branches[$1]}"
    git clone -b "$(echo "${ruinedfooocus_branches[$1]}" | cut -d' ' -f1)" "$ruinedfooocus_repo"
    echo;echo "Done... (Press enter)"
  fi
  read
}
ruinedfooocus_loop() {
  while true; do
    options=()
    for branch in "${ruinedfooocus_branches[@]}"; do
      options+=("$(echo $branch|cut -d'|' -f1)")
    done
    options+=("Back")
    menu
    if [ $selected -lt ${#ruinedfooocus_branches[@]} ]; then
      git_clone $selected
    else
      break
    fi
  done
}

use_torch() {
  index_url=$(echo "${torch_options[$1]}" | cut -d'|' -f2)
  if [ \! -d "$python_embeded_dir" ]; then
    echo "You need to install python first."
    read
    return
  fi
  if [ \! -d "$ruinedfooocus_dir" ]; then
    echo "You need to download RuinedFooocus first."
    read
    return
  fi
  clear
  header
  case $index_url in
    auto)
      rm -f $ruinedfooocus_dir/freezetorch
      $python_embeded_dir/bin/pip uninstall -y torch torchvision torchaudio
      echo "Torch unfrozen"
      ;;
    freeze)
      touch $ruinedfooocus_dir/freezetorch
      echo "Torch frozen"
      ;;
    unfreeze)
      rm -f $ruinedfooocus_dir/freezetorch
      echo "Torch unfrozen"
      ;;
    *)
      echo "Remove old version"
      $python_embeded_dir/bin/pip uninstall -y torch torchvision torchaudio
      echo "Install torch from $index_url"
      $python_embeded_dir/bin/pip install --pre torch torchvision torchaudio --index-url $index_url
      echo "Lock torch version"
      touch $ruinedfooocus_dir/freezetorch
      ;;
  esac
  echo;echo "Done... (Press enter)"
  read
}
torch_loop() {
  while true; do
    options=()
    for torch in "${torch_options[@]}"; do
      options+=("$(echo $torch|cut -d'|' -f1)")
    done
    options+=("Back")
    menu
    if [ $selected -lt ${#torch_options[@]} ]; then
      use_torch $selected
    else
      break
    fi
  done
}


main_loop() {
  while true; do
    options=(
      "Python"
      "RuinedFoocus"
      "Torch"
      "Write run.sh script"
      "Start RuinedFooocus"
      "Quit"
    )
    menu
    case $selected in
      0)
        python_loop
        ;;
      1)
        ruinedfooocus_loop
        ;;
      2)
        torch_loop
        ;;
      3)
        echo "$python_embeded_dir/bin/python $ruinedfooocus_dir/entry_with_update.py" > run.sh
	chmod 755 run.sh
        echo;echo "Done... (Press enter)"
        read
        ;;
      4)
        $python_embeded_dir/bin/python $ruinedfooocus_dir/entry_with_update.py
        echo;echo "Done... (Press enter)"
        read
        ;;
      *)
        break
        ;;
    esac
  done
}


main_loop
