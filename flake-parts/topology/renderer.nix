# This is largely AI-generated
{
  topologyConfig,
  hostPlacements,
  topologySource,
  pkgs,
}:
let
  inherit (pkgs) lib;

  rendererPkgs = pkgs // {
    elk-to-svg = pkgs.elk-to-svg.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace main.js \
          --replace-fail 'styleBg["stroke-width"] = style["stroke-width"];' \
          'styleBg["stroke-width"] = Number(style["stroke-width"]) + 4;'

        substituteInPlace main.js \
          --replace-fail $'    if (bendPoints[i].shared == true) {\n      path += ` L ''${bx} ''${by}`;\n    } else {\n      const next = bendPoints[i + 1] || endPoint;\n      const nx = next.x;\n      const ny = next.y;\n\n      // Calculate the lengths of the line segments\n      const d1 = Math.sqrt((bx - lx) ** 2 + (by - ly) ** 2);\n      const d2 = Math.sqrt((nx - bx) ** 2 + (ny - by) ** 2);' \
          $'    const next = bendPoints[i + 1] || endPoint;\n    const nx = next.x;\n    const ny = next.y;\n    const d1 = Math.sqrt((bx - lx) ** 2 + (by - ly) ** 2);\n    const d2 = Math.sqrt((nx - bx) ** 2 + (ny - by) ** 2);\n    const directionCross = (bx - lx) * (ny - by) - (by - ly) * (nx - bx);\n    const directionDot = (bx - lx) * (nx - bx) + (by - ly) * (ny - by);\n    const isStraight = directionDot > 0 && Math.abs(directionCross) / (d1 * d2) < 0.01;\n\n    if (bendPoints[i].shared == true || isStraight) {\n      path += ` L ''${bx} ''${by}`;\n    } else {'
      '';
    });
  };

  inherit
    (import "${topologySource}/topology/renderers/elk/lib.nix" {
      config = topologyConfig;
      inherit lib;
      pkgs = rendererPkgs;
    })
    mkDiagram
    mkEdge
    mkLabel
    mkPort
    mkRender
    pathStyleFromNetworkStyle
    ;

  placementNames = [
    "vps"
    "roaming"
    "home"
  ];

  hostNames =
    let
      names = hostPlacements |> lib.attrNames |> lib.sort builtins.lessThan;
    in
    assert lib.assertMsg (lib.all (
      name: lib.elem hostPlacements.${name} placementNames
    ) names) "Every topology host must have a valid placement";
    assert lib.assertMsg (lib.all (
      name: lib.hasAttr name topologyConfig.nodes
    ) names) "Every configured host must have a topology node";
    names;

  sites = {
    backbones = [ "backbones" ];
    right = [ "right" ];
    stack = [ "stack" ];
    vps = [
      "right"
      "02-vps"
    ];
    roaming = [
      "stack"
      "02-roaming"
    ];
    home = [
      "stack"
      "03-home"
    ];
  };

  nodeSites =
    name:
    if name == "internet" then
      sites.backbones
    else if name == "home-router" then
      sites.home
    else
      sites.${hostPlacements.${name}};

  elkPath = lib.concatMap (site: [
    "children"
    "site:${site}"
  ]);
  childPath =
    site: child:
    elkPath site
    ++ [
      "children"
      child
    ];
  elkId = lib.concatStringsSep ".";

  nodePath = node: childPath (nodeSites node.id) "node:${node.id}";
  nodeId = node: node |> nodePath |> elkId;
  portPath =
    node: port:
    nodePath node
    ++ [
      "ports"
      port
    ];
  interfacePath = node: interface: portPath node "interface:${interface}";
  interfaceId = node: interface: "${nodeId node}.ports.interface:${interface}";

  nebulaPath = childPath sites.backbones "net:nebula";
  nebulaId = elkId nebulaPath;
  isVpsNode = node: (hostPlacements.${node.id} or null) == "vps";
  nebulaPort = node: "${nebulaId}.ports.${if isVpsNode node then "vps" else "default"}";
  internetVpsPort = "${nodeId topologyConfig.nodes.internet}.ports.vps";

  networkLegendPath = childPath sites.right "legend:networks";

  isRoamingNode = node: (hostPlacements.${node.id} or null) == "roaming";
  roamingNodes =
    hostNames
    |> lib.filter (name: hostPlacements.${name} == "roaming")
    |> map (name: topologyConfig.nodes.${name});
  choicePath = node: childPath sites.roaming "choice:${node.id}";
  choiceId = node: node |> choicePath |> elkId;
  choicePort = node: port: "${choiceId node}.ports.${port}";
  choiceTargetPath = node: target: childPath sites.roaming "choice-target:${node.id}:${target}";
  choiceTargetId = node: target: elkId (choiceTargetPath node target);
  choiceTargetPort = node: target: "${choiceTargetId node target}.ports.default";
  choiceSvg = pkgs.writeText "roaming-underlay-choice.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
      <polygon points="12,1 23,12 12,23 1,12" fill="#161b22" stroke="#b6beca" stroke-width="2"/>
    </svg>
  '';

  forceModelOrder = {
    "org.eclipse.elk.layered.crossingMinimization.forceNodeModelOrder" = true;
  };

  mkSite =
    {
      path,
      name ? null,
      direction,
      style,
      extraLayoutOptions ? { },
    }:
    lib.setAttrByPath (elkPath path) (
      {
        inherit style;
        layoutOptions = {
          "org.eclipse.elk.algorithm" = "layered";
          "org.eclipse.elk.direction" = direction;
          "org.eclipse.elk.edgeRouting" = "ORTHOGONAL";
          "org.eclipse.elk.padding" = "[top=35,left=35,bottom=35,right=35]";
          "org.eclipse.elk.spacing.nodeNode" = 35;
          "org.eclipse.elk.layered.spacing.nodeNodeBetweenLayers" = 60;
          "org.eclipse.elk.nodeLabels.placement" = "[H_LEFT, V_TOP, INSIDE]";
        }
        // lib.optionalAttrs (name != null) {
          "org.eclipse.elk.alignment" = "RIGHT";
        }
        // extraLayoutOptions;
      }
      // lib.optionalAttrs (name != null) {
        labels.title =
          mkLabel name 1.3 {
            fill = style.stroke;
            "font-weight" = "700";
          }
          // {
            width = 0;
          };
      }
    );

  transparentSite = path: {
    inherit path;
    direction = "DOWN";
    style = {
      fill = "#0d1117";
      "fill-opacity" = 0;
      stroke = "none";
    };
  };
  orderedTransparentSite =
    path:
    transparentSite path
    // {
      extraLayoutOptions = forceModelOrder;
    };
  rightSite = orderedTransparentSite sites.right // {
    extraLayoutOptions = forceModelOrder // {
      "org.eclipse.elk.spacing.nodeNode" = 55;
    };
  };

  siteDefinitions = [
    (mkSite (orderedTransparentSite sites.stack))
    (mkSite (transparentSite sites.backbones))
    (mkSite rightSite)
    (mkSite {
      path = sites.vps;
      name = "VPS hosts";
      direction = "RIGHT";
      style = {
        fill = "#15171b";
        "fill-opacity" = 0.35;
        stroke = "#707379";
        "stroke-dasharray" = "3,9";
        "stroke-width" = 2;
        rx = 14;
      };
      extraLayoutOptions = forceModelOrder;
    })
    (mkSite {
      path = sites.roaming;
      name = "Roaming clients";
      direction = "RIGHT";
      style = {
        fill = "#191817";
        "fill-opacity" = 0.4;
        stroke = "#d6b18a";
        "stroke-dasharray" = "12,8";
        "stroke-width" = 2;
        rx = 14;
      };
      extraLayoutOptions = forceModelOrder;
    })
    (mkSite {
      path = sites.home;
      name = "Home LAN";
      direction = "RIGHT";
      style = {
        fill = "#0f1c1a";
        "fill-opacity" = 0.72;
        stroke = "#78dba9";
        "stroke-width" = 3;
        rx = 18;
      };
      extraLayoutOptions = forceModelOrder // {
        "org.eclipse.elk.layered.spacing.nodeNodeBetweenLayers" = 25;
      };
    })
  ];

  interfaceLabels =
    node: interface:
    if node.id == "internet" || (node.id == "home-router" && interface.network == "home-lan") then
      { }
    else
      let
        networkStyle = lib.optionalAttrs (interface.network != null && !isRoamingNode node) {
          fill = topologyConfig.networks.${interface.network}.style.primaryColor;
        };
        summary =
          if interface.addresses == [ ] then
            interface.id
          else
            "${interface.id}: ${lib.concatStringsSep ", " interface.addresses}";
      in
      {
        summary = mkLabel summary 0.9 networkStyle;
      };

  portSide =
    node: interface:
    if
      node.id == "internet"
      || isVpsNode node
      || (node.id == "home-router" && interface.network == "home-lan")
    then
      "WEST"
    else
      "EAST";

  mkChoiceTarget =
    node:
    {
      target,
      label,
      network,
      fill,
    }:
    lib.setAttrByPath (choiceTargetPath node target) {
      width = 150;
      height = 32;
      style = {
        inherit fill;
        stroke = topologyConfig.networks.${network}.style.primaryColor;
        rx = 8;
      };
      labels.title = mkLabel label 0.75 {
        fill = topologyConfig.networks.${network}.style.primaryColor;
      };
      properties = {
        "nodeLabels.placement" = "[H_CENTER, V_CENTER, INSIDE]";
        "portConstraints" = "FIXED_SIDE";
      };
      ports.default = mkPort { properties."port.side" = "WEST"; };
    };

  choiceToElk =
    node:
    let
      underlayInterface = lib.findFirst (
        interface: interface.network != "nebula"
      ) (throw "Roaming host `${node.id}` has no underlay interface") (lib.attrValues node.interfaces);
    in
    [
      (lib.setAttrByPath (choicePath node) {
        svg = {
          file = choiceSvg;
          scale = 1;
        };
        properties."portConstraints" = "FIXED_ORDER";
        ports = {
          input = mkPort { properties."port.side" = "WEST"; };
          home = mkPort { properties."port.side" = "EAST"; };
          internet = mkPort { properties."port.side" = "EAST"; };
        };
      })
      (mkChoiceTarget node {
        target = "home";
        label = "At home: Home LAN";
        network = "home-lan";
        fill = "#0f1c1a";
      })
      (mkChoiceTarget node {
        target = "internet";
        label = "Away: Public Internet";
        network = "internet";
        fill = "#191817";
      })
      (mkEdge (interfaceId node underlayInterface.id) (choicePort node "input") false {
        style.stroke = "#8b949e";
      })
      (mkEdge (choicePort node "home") (choiceTargetPort node "home") false {
        style = pathStyleFromNetworkStyle topologyConfig.networks.home-lan.style;
      })
      (mkEdge (choicePort node "internet") (choiceTargetPort node "internet") false {
        style = pathStyleFromNetworkStyle topologyConfig.networks.internet.style;
      })
    ];

  physicalConnectionToElk =
    node: interface: connection:
    let
      otherNode = topologyConfig.nodes.${connection.node};
      otherInterface = otherNode.interfaces.${connection.interface};
      network = if interface.network != null then interface.network else otherInterface.network;
      reciprocalConnection = lib.any (
        candidate: candidate.node == node.id && candidate.interface == interface.id
      ) otherInterface.physicalConnections;
      shouldRender = !reciprocalConnection || node.id < connection.node;
      isVisible =
        !interface.renderer.hidePhysicalConnections && !otherInterface.renderer.hidePhysicalConnections;
      connectsInternetToVps = node.id == "internet" && isVpsNode otherNode;
      from = if connectsInternetToVps then internetVpsPort else interfaceId node interface.id;
    in
    lib.optionalAttrs (shouldRender && isVisible) (
      mkEdge from (interfaceId otherNode otherInterface.id)
        (connection.renderer.reverse && !connectsInternetToVps)
        {
          style = lib.optionalAttrs (network != null) (
            pathStyleFromNetworkStyle topologyConfig.networks.${network}.style
          );
        }
    );

  nodeInterfaceToElk =
    node: interface:
    [
      (lib.setAttrByPath (interfacePath node interface.id) (mkPort {
        properties."port.side" = portSide node interface;
        labels = interfaceLabels node interface;
      }))
    ]
    ++ lib.optional (interface.network == "nebula") (
      mkEdge (interfaceId node interface.id) (nebulaPort node) (isVpsNode node) {
        style = pathStyleFromNetworkStyle topologyConfig.networks.nebula.style;
      }
    )
    ++ map (physicalConnectionToElk node interface) interface.physicalConnections;

  inlineSvg =
    file:
    let
      withoutPrefix = lib.head (lib.tail (lib.splitString "<svg " (builtins.readFile file)));
      content = lib.head (lib.splitString "</svg>" withoutPrefix);
    in
    ''<svg tw="w-12 h-12 ml-4" ${content}</svg>'';

  renderCompactRouter =
    node:
    let
      html = ''
        <div tw="flex flex-col w-full h-full items-center">
          <div tw="flex flex-row w-full h-full items-center bg-[#101419] rounded-xl px-6 py-2 text-[#e3e6eb] font-mono" style="font-family: 'JetBrains Mono'">
            <div tw="flex flex-col min-h-18 justify-center flex-1 min-w-0">
              <span tw="text-2xl font-bold">${node.name}</span>
              ${lib.optionalString (node.hardware.info != "") ''
                <span tw="text-xs">${node.hardware.info}</span>
              ''}
            </div>
            ${inlineSvg (topologyConfig.lib.icons.get node.deviceIcon)}
          </div>
        </div>
      '';
    in
    pkgs.runCommand "compact-router-${node.id}.svg" { } ''
      ${lib.getExe pkgs.html-to-svg} \
        --font ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf \
        --font-bold ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Bold.ttf \
        --width 360 \
        --height auto \
        ${pkgs.writeText "compact-router-${node.id}.html" html} \
        $out
    '';

  nodeToElk =
    node:
    let
      cardNode = node // {
        interfaces = { };
      };
      render =
        if node.deviceType == "router" then
          renderCompactRouter cardNode
        else
          topologyConfig.lib.renderers.svg.node.mkPreferredRender cardNode;
    in
    [
      (lib.setAttrByPath (nodePath node) {
        svg = {
          file = render;
          scale = 0.8;
        };
        properties = {
          "portConstraints" = "FIXED_SIDE";
          "portLabels.placement" = "OUTSIDE";
        };
      })
    ]
    ++ lib.concatMap (nodeInterfaceToElk node) (lib.attrValues node.interfaces);

  invisibleStyle = {
    fill = "none";
    stroke = "none";
  };
  mkInvisiblePort =
    side:
    mkPort {
      properties."port.side" = side;
      style = invisibleStyle;
    };

  nebulaDefinition = lib.setAttrByPath nebulaPath {
    width = 0;
    height = 0;
    style = invisibleStyle;
    properties."portConstraints" = "FIXED_SIDE";
    ports = {
      default = mkInvisiblePort "WEST" // {
        width = 0;
        height = 0;
      };
      vps = mkInvisiblePort "EAST" // {
        width = 0;
        height = 0;
      };
    };
  };

  internetVpsPortDefinition =
    lib.setAttrByPath (portPath topologyConfig.nodes.internet "vps")
      (mkPort {
        properties."port.side" = "EAST";
      });

  networkLegendDefinition = lib.setAttrByPath networkLegendPath {
    svg = {
      file = topologyConfig.lib.renderers.svg.net.mkOverview;
      scale = 0.8;
    };
    properties."org.eclipse.elk.alignment" = "RIGHT";
  };

  diagram = mkDiagram (
    [
      {
        layoutOptions = {
          "org.eclipse.elk.hierarchyHandling" = "INCLUDE_CHILDREN";
          "org.eclipse.elk.direction" = "RIGHT";
        };
      }
      nebulaDefinition
      internetVpsPortDefinition
      networkLegendDefinition
    ]
    ++ siteDefinitions
    ++ lib.concatMap nodeToElk (lib.attrValues topologyConfig.nodes)
    ++ lib.concatMap choiceToElk roamingNodes
  );
in
pkgs.runCommand "homelab-topology" { } ''
  mkdir -p $out
  cp ${mkRender "main" diagram} $out/main.svg
''
