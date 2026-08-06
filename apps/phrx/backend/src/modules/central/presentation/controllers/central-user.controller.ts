import bcrypt from "bcryptjs";
import { z } from "zod";
import { Role } from "../../../../infrastructure/prisma/central/generated/central";
import { prismaCentral } from "../../../../infrastructure/prisma/prisma-central.service";
import { serializeForJson } from "../../../../shared/http/serialize-json";
import { parseJsonBody, parseSearchParams } from "../../../../shared/http/request-validation";
import {
  listSuccess,
  pagedSuccess,
  resolvePage,
  resolvePageSize,
  slicePage,
} from "../helpers/paged-response";

const createUserSchema = z.object({
  name: z.string().trim().min(1),
  email: z.string().trim().pipe(z.email()),
  password: z.string().min(6),
  role: z.enum(["superadmin", "admin", "usuario"]).default("superadmin"),
  active: z.coerce.boolean().optional().default(true),
});

const updateUserSchema = z.object({
  name: z.string().trim().min(1).optional(),
  email: z.string().trim().pipe(z.email()).optional(),
  password: z.string().min(6).optional(),
  role: z.enum(["superadmin", "admin", "usuario"]).optional(),
  active: z.coerce.boolean().optional(),
});

const listUsersQuerySchema = z.object({
  role: z.enum(["superadmin", "admin", "usuario"]).optional(),
  q: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
  includeInactive: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .optional(),
});

function mapUser(user: any) {
  return {
    id: user.id.toString(),
    name: user.name,
    email: user.email,
    role: user.role,
    active: user.active,
    lastLoginAt: user.lastLoginAt,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

function parseRole(input: string | undefined, fallback: Role): Role {
  if (input === "superadmin") return Role.superadmin;
  if (input === "admin") return Role.admin;
  if (input === "usuario") return Role.usuario;
  return fallback;
}

export class CentralUserController {
  async list(url: URL): Promise<Response> {
    const query = parseSearchParams(url, listUsersQuerySchema);
    const { role, includeInactive = false, q } = query;
    const prisma = prismaCentral as any;
    const search = q?.trim();

    const where = {
      deletedAt: null,
      ...(includeInactive ? {} : { active: true }),
      ...(role ? { role } : { role: Role.superadmin }),
      ...(search
        ? {
            OR: [
              { name: { contains: search } },
              { email: { contains: search } },
            ],
          }
        : {}),
    };

    if (query.page == null) {
      const users = await prisma.user.findMany({
        where,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          active: true,
          lastLoginAt: true,
          createdAt: true,
          updatedAt: true,
        },
      });
      return listSuccess(users.map(mapUser));
    }

    const page = resolvePage(query.page);
    const pageSize = resolvePageSize(query.pageSize);
    const [totalCount, rows] = await prisma.$transaction([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          active: true,
          lastLoginAt: true,
          createdAt: true,
          updatedAt: true,
        },
        skip: (page - 1) * pageSize,
        take: pageSize + 1,
      }),
    ]);
    const { items, hasMore } = slicePage(rows, page, pageSize);
    return pagedSuccess(items.map(mapUser), {
      page,
      pageSize,
      hasMore,
      totalCount,
    });
  }

  async create(req: Request): Promise<Response> {
    const body = await parseJsonBody(req, createUserSchema);
    const prisma = prismaCentral as any;
    const email = body.email.trim().toLowerCase();

    const existing = await prisma.user.findFirst({
      where: { email, deletedAt: null },
    });
    if (existing) {
      return Response.json(
        { error: { message: `Já existe um utilizador com o e-mail ${email}.` } },
        { status: 409 },
      );
    }

    const hashedPassword = await bcrypt.hash(body.password, 10);
    const user = await prisma.user.create({
      data: {
        name: body.name,
        email,
        password: hashedPassword,
        role: parseRole(body.role, Role.superadmin),
        active: body.active ?? true,
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        active: true,
        lastLoginAt: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return Response.json(serializeForJson(mapUser(user)), { status: 201 });
  }

  async update(userId: string, req: Request): Promise<Response> {
    const body = await parseJsonBody(req, updateUserSchema);
    const prisma = prismaCentral as any;
    const id = BigInt(userId);

    const current = await prisma.user.findFirst({
      where: { id, deletedAt: null },
    });
    if (!current) {
      return Response.json(
        { error: { message: "Utilizador não encontrado." } },
        { status: 404 },
      );
    }

    if (body.email) {
      const email = body.email.trim().toLowerCase();
      const clash = await prisma.user.findFirst({
        where: { email, deletedAt: null, NOT: { id } },
      });
      if (clash) {
        return Response.json(
          { error: { message: `Já existe um utilizador com o e-mail ${email}.` } },
          { status: 409 },
        );
      }
    }

    const user = await prisma.user.update({
      where: { id },
      data: {
        ...(body.name != null ? { name: body.name } : {}),
        ...(body.email != null ? { email: body.email.trim().toLowerCase() } : {}),
        ...(body.password != null
          ? { password: await bcrypt.hash(body.password, 10) }
          : {}),
        ...(body.role != null ? { role: parseRole(body.role, current.role) } : {}),
        ...(body.active != null ? { active: body.active } : {}),
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        active: true,
        lastLoginAt: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return Response.json(serializeForJson(mapUser(user)));
  }

  async deactivate(userId: string): Promise<Response> {
    const prisma = prismaCentral as any;
    const id = BigInt(userId);
    const current = await prisma.user.findFirst({
      where: { id, deletedAt: null },
    });
    if (!current) {
      return Response.json(
        { error: { message: "Utilizador não encontrado." } },
        { status: 404 },
      );
    }

    const user = await prisma.user.update({
      where: { id },
      data: { active: false },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        active: true,
        lastLoginAt: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return Response.json(serializeForJson(mapUser(user)));
  }
}
